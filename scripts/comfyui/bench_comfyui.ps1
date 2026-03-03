param(
  [string]$Server = "http://127.0.0.1:8000",

  [string]$Workflow = "scripts/comfyui/workflows/character_v2_pose_pack_api.json",
  [string]$Init = "assets/images/themes/jungle/character_v2.png",

  [string]$Prompt = "cute friendly jungle explorer kid character, full body, centered, bold outline, simple shapes, high contrast, clean silhouette, cartoon style, consistent outfit, consistent hat, consistent backpack, waving with one hand",
  [string]$Negative = "scary, creepy, gore, realistic, blurry, noisy, text, watermark, logo, multiple characters, cropped, out of frame, cut off, extra fingers, extra limbs, bad hands",

  [int]$Steps = 28,
  [double]$Cfg = 6.5,
  [double]$Denoise = 0.35,
  [int]$Seed = 123,

  [int]$Runs = 3,
  [switch]$VarySeed,
  [string]$OutRoot = "artifacts/comfyui/bench"
)

$ErrorActionPreference = 'Stop'

if ($Runs -lt 1) {
  Write-Error "Runs must be >= 1"
  exit 2
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outDir = Join-Path $OutRoot "bench_$timestamp"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "[Bench] Server:   $Server"
Write-Host "[Bench] Workflow: $Workflow"
Write-Host "[Bench] Steps=$Steps CFG=$Cfg Denoise=$Denoise Seed=$Seed Runs=$Runs"
Write-Host "[Bench] VarySeed: $VarySeed"
Write-Host "[Bench] OutDir:   $outDir"
Write-Host "---"

$times = New-Object System.Collections.Generic.List[double]

for ($i = 1; $i -le $Runs; $i++) {
  Write-Host "[Bench] Run $i/$Runs..."
  $sw = [System.Diagnostics.Stopwatch]::StartNew()

  $runSeed = if ($VarySeed) { $Seed + ($i - 1) } else { $Seed }
  Write-Host "[Bench] Seed: $runSeed"

  $runOutDir = Join-Path $outDir ("run_{0}" -f $i)
  New-Item -ItemType Directory -Force -Path $runOutDir | Out-Null

  $dartArgs = @(
    'run',
    'scripts/generate_images_comfyui.dart',
    '--server', $Server,
    '--workflow', $Workflow,
    '--init', $Init,
    '--prompt', $Prompt,
    '--negative', $Negative,
    '--steps', "$Steps",
    '--cfg', "$Cfg",
    '--denoise', "$Denoise",
    '--seed', "$runSeed",
    '--count', '1',
    '--out', $runOutDir
  )

  $dartOutput = & dart @dartArgs 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Error "[Bench] dart exited with code $LASTEXITCODE"
    $dartOutput | ForEach-Object { Write-Host $_ }
    exit $LASTEXITCODE
  }

  $sw.Stop()
  $sec = [Math]::Round($sw.Elapsed.TotalSeconds, 2)
  $times.Add($sec)
  $perStep = [Math]::Round(($sw.Elapsed.TotalSeconds / [Math]::Max(1, $Steps)), 4)
  Write-Host "[Bench] Time: ${sec}s (~${perStep}s/step)"
  Write-Host ""
}

$sorted = $times.ToArray() | Sort-Object { [double]$_ }
$midIndex = [int][Math]::Floor($sorted.Length / 2)
$median = if ($sorted.Length % 2 -eq 1) {
  $sorted[$midIndex]
} else {
  ($sorted[$midIndex - 1] + $sorted[$midIndex]) / 2.0
}

$min = ($sorted | Select-Object -First 1)
$max = ($sorted | Select-Object -Last 1)
$avg = [Math]::Round((($times | Measure-Object -Average).Average), 2)
$median = [Math]::Round($median, 2)

Write-Host "---"
Write-Host "[Bench] Times (s): $($times -join ', ')"
Write-Host "[Bench] Min/Med/Avg/Max (s): $min / $median / $avg / $max"
Write-Host "[Bench] Median per step: $([Math]::Round(($median / [Math]::Max(1, $Steps)), 4)) s/step"
