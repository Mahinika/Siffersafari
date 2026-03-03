param(
  [string]$Init = "assets/images/themes/jungle/character_v2.png",
  [string]$OutDir = "",
  [string]$Workflow = "scripts/comfyui/workflows/img2img_color_api.json",
  [string]$PreferredWorkflow = "scripts/comfyui/workflows/character_v2_pose_pack_api.json",
  [string]$Server = "",
  [int]$Count = 8,
  [double]$Denoise = 0.35,
  [int]$Steps = 28,
  [double]$Cfg = 6.5,
  [int]$Width = 1024,
  [int]$Height = 1024,
  [int]$Tolerance = 18,
  [switch]$AlphaAll
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path "artifacts/comfyui" ("pose_pack_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
}

if ([string]::IsNullOrWhiteSpace($Server)) {
  if (-not [string]::IsNullOrWhiteSpace($env:COMFYUI_SERVER)) {
    $Server = $env:COMFYUI_SERVER
  } elseif (-not [string]::IsNullOrWhiteSpace($env:COMFYUI_URL)) {
    $Server = $env:COMFYUI_URL
  } else {
    $Server = "http://127.0.0.1:8000"
  }
}

if (-not (Test-Path -LiteralPath $Init)) {
  throw "Init image not found: $Init"
}

$usedPreferred = $false

if (-not $PSBoundParameters.ContainsKey('Workflow')) {
  if (-not [string]::IsNullOrWhiteSpace($PreferredWorkflow) -and (Test-Path -LiteralPath $PreferredWorkflow)) {
    $preferredText = Get-Content -LiteralPath $PreferredWorkflow -Raw -ErrorAction SilentlyContinue
    try {
      $preferredJson = $preferredText | ConvertFrom-Json -ErrorAction Stop

      $looksLikeGraph = $false
      foreach ($p in $preferredJson.PSObject.Properties) {
        $node = $p.Value
        if ($null -eq $node) { continue }
        $names = $node.PSObject.Properties.Name
        if ($names -contains 'class_type' -and $names -contains 'inputs') {
          $looksLikeGraph = $true
          break
        }
      }

      $hasPositive = ($preferredText -match "__POSITIVE_PROMPT__")
      $hasInit = ($preferredText -match "__INIT_IMAGE__")

      if ($looksLikeGraph -and $hasPositive -and $hasInit) {
        $Workflow = $PreferredWorkflow
        $usedPreferred = $true
      } else {
        Write-Host "---"
        Write-Host "NOTE: Preferred workflow exists but was ignored (not a valid API graph and/or missing placeholders):"
        Write-Host "      $PreferredWorkflow"
        $reasons = @()
        if (-not $looksLikeGraph) { $reasons += "not an API-format node graph" }
        if (-not $hasPositive) { $reasons += "missing __POSITIVE_PROMPT__" }
        if (-not $hasInit) { $reasons += "missing __INIT_IMAGE__" }
        Write-Host "      Reason: $($reasons -join '; ')"
        Write-Host "      Using fallback workflow instead: $Workflow"
      }
    } catch {
      Write-Host "---"
      Write-Host "NOTE: Preferred workflow exists but could not be parsed as JSON; ignoring it:"
      Write-Host "      $PreferredWorkflow"
      Write-Host "      Using fallback workflow instead: $Workflow"
    }
  }
}

if (-not (Test-Path -LiteralPath $Workflow)) {
  throw "Workflow not found: $Workflow"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$basePrompt = "cute friendly jungle explorer kid, full body, centered, bold outline, simple shapes, high contrast, clean silhouette, cartoon style, solid light background, same character, consistent outfit, consistent hat, consistent backpack"
$negative = "scary, creepy, gore, realistic, blurry, noisy, text, watermark, logo, multiple characters, character sheet, cropped, out of frame, cut off, extra fingers, extra limbs, bad hands"

$poses = @(
  @{ name = "idle";       prompt = "$basePrompt, neutral idle pose, relaxed smile" },
  @{ name = "wave";       prompt = "$basePrompt, waving with one hand" },
  @{ name = "jump";       prompt = "$basePrompt, jumping, happy" },
  @{ name = "celebrate";  prompt = "$basePrompt, celebrating, arms up" },
  @{ name = "think";      prompt = "$basePrompt, thinking pose, hand on chin" },
  @{ name = "sad";        prompt = "$basePrompt, sad expression, slumped shoulders" },
  @{ name = "surprised";  prompt = "$basePrompt, surprised expression" },
  @{ name = "point";      prompt = "$basePrompt, pointing to the side with one hand" }
)

Write-Host "---"
Write-Host "Pose-pack generation"
Write-Host "Server:    $Server"
Write-Host "Workflow:  $Workflow"
Write-Host "Preferred: $PreferredWorkflow"
Write-Host "Init:      $Init"
Write-Host "OutDir:    $OutDir"
Write-Host "Count:     $Count"
Write-Host "Denoise:   $Denoise"
Write-Host "Steps/Cfg: $Steps / $Cfg"
Write-Host "Size:      ${Width}x${Height}"
Write-Host "AlphaAll:  $AlphaAll"

if ((-not $PSBoundParameters.ContainsKey('Workflow')) -and (-not $usedPreferred)) {
  Write-Host "---"
  Write-Host "TIP: For better consistency, export your ComfyUI workflow as API format to:" 
  Write-Host "     $PreferredWorkflow"
  Write-Host "     (ComfyUI: Workflow -> Save (API Format))"
}

foreach ($pose in $poses) {
  $poseName = $pose.name
  $posePrompt = $pose.prompt

  $poseDir = Join-Path $OutDir $poseName
  $rawDir = Join-Path $poseDir "raw"
  $alphaDir = Join-Path $poseDir "alpha"

  New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
  if ($AlphaAll) {
    New-Item -ItemType Directory -Force -Path $alphaDir | Out-Null
  }

  Write-Host "---"
  Write-Host "Generating pose: $poseName"

  dart run scripts/generate_images_comfyui.dart `
    --server $Server `
    --workflow $Workflow `
    --init $Init `
    --prompt $posePrompt `
    --negative $negative `
    --width $Width `
    --height $Height `
    --denoise $Denoise `
    --steps $Steps `
    --cfg $Cfg `
    --seed -1 `
    --count $Count `
    --out $rawDir

  if ($LASTEXITCODE -ne 0) {
    throw "generate_images_comfyui failed for pose '$poseName' (exit code: $LASTEXITCODE)"
  }

  if ($AlphaAll) {
    Write-Host "Background removal for pose: $poseName"
    $pngs = Get-ChildItem -LiteralPath $rawDir -File | Where-Object { $_.Name.ToLower().EndsWith('.png') }
    foreach ($p in $pngs) {
      $outPng = Join-Path $alphaDir $p.Name
      dart run scripts/make_background_transparent.dart --in $p.FullName --out $outPng --tolerance $Tolerance --protect-radius 2

      if ($LASTEXITCODE -ne 0) {
        throw "make_background_transparent failed for pose '$poseName' on file '$($p.Name)' (exit code: $LASTEXITCODE)"
      }
    }
  }
}

Write-Host "---"
Write-Host "KLAR: Pose-pack genererat i: $OutDir"