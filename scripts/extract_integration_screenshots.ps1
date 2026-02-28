param(
  [Parameter(Mandatory = $false)]
  [string]$BuildDir = (Join-Path $PSScriptRoot '..\build'),

  [Parameter(Mandatory = $false)]
  [string]$OutDir = (Join-Path $PSScriptRoot '..\artifacts\UI TEST 1'),

  [Parameter(Mandatory = $false)]
  [string]$ResponseJson
)

$ErrorActionPreference = 'Stop'

function Find-ResponseJson {
  param([string]$Root)

  if (-not (Test-Path -LiteralPath $Root)) {
    throw "Build dir not found: $Root"
  }

  $candidates = @()
  $patterns = @(
    '*integration*response*.json',
    '*integration*results*.json',
    '*integration*test*.json'
  )

  foreach ($pattern in $patterns) {
    $items = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
    if ($items) { $candidates += $items }
  }

  # Also consider the common default path.
  $default = Join-Path $Root 'integration_response_data.json'
  if (Test-Path -LiteralPath $default) {
    $candidates += Get-Item -LiteralPath $default
  }

  $candidates = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -Unique
  if (-not $candidates -or $candidates.Count -eq 0) {
    throw "No integration response JSON found under: $Root"
  }

  return $candidates[0].FullName
}

function Get-ScreenshotListFromJson {
  param([object]$Json)

  # Try a few shapes:
  # - {"screenshots": [...]}
  # - {"data": {"screenshots": [...]}}
  # - {"result": "true/false", "data": {"screenshots": [...]}}
  if ($null -ne $Json.screenshots) { return @($Json.screenshots) }
  if ($null -ne $Json.data -and $null -ne $Json.data.screenshots) { return @($Json.data.screenshots) }

  # Some runners wrap the response.
  if ($null -ne $Json.message) {
    try {
      $inner = $Json.message | ConvertFrom-Json
      if ($null -ne $inner.data -and $null -ne $inner.data.screenshots) { return @($inner.data.screenshots) }
    } catch {
      # ignore
    }
  }

  return @()
}

if ([string]::IsNullOrWhiteSpace($ResponseJson)) {
  $ResponseJson = Find-ResponseJson -Root $BuildDir
}

Write-Output "using_response_json=$ResponseJson"

$raw = Get-Content -LiteralPath $ResponseJson -Raw
$json = $raw | ConvertFrom-Json
$shots = Get-ScreenshotListFromJson -Json $json

if (-not $shots -or $shots.Count -eq 0) {
  throw "No screenshots found in response JSON ($ResponseJson)."
}

# Prepare output folder.
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Get-ChildItem -LiteralPath $OutDir -File -Filter '*.png' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$written = 0
foreach ($s in $shots) {
  $name = $s.screenshotName
  if ([string]::IsNullOrWhiteSpace($name)) { $name = $s.name }
  if ([string]::IsNullOrWhiteSpace($name)) { $name = "shot_$written" }

  $bytes = $s.bytes
  if ($null -eq $bytes) {
    throw "Screenshot '$name' missing bytes"
  }

  [byte[]]$b = $null
  if ($bytes -is [string]) {
    $b = [Convert]::FromBase64String($bytes)
  } else {
    # Convert int array -> byte[]
    $b = [byte[]]$bytes
  }

  $fileName = ($name -replace '[^a-zA-Z0-9_\-]', '_') + '.png'
  $outPath = Join-Path $OutDir $fileName
  [System.IO.File]::WriteAllBytes($outPath, $b)
  $written++
}

Write-Output "screenshots_written=$written"
Write-Output "out_dir=$OutDir"
