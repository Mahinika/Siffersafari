param(
  [string]$PythonPath = "",
  [string]$MainPyPath = "",

  [string]$UserDirectory = "",
  [string]$InputDirectory = "",
  [string]$OutputDirectory = "",
  [string]$FrontEndRoot = "",
  [string]$BaseDirectory = "",
  [string]$DatabaseUrl = "",
  [string]$ExtraModelPathsConfig = "",

  [string]$Listen = "127.0.0.1",
  [int]$Port = 8000,

  [switch]$EnableManager,
  [ValidateSet('auto', 'pytorch')]
  [string]$CrossAttention = 'pytorch',
  [switch]$NoFp16,

  [string[]]$ExtraArgs
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($PythonPath)) {
  if (-not [string]::IsNullOrWhiteSpace($env:COMFYUI_PYTHON)) {
    $PythonPath = $env:COMFYUI_PYTHON
  } else {
    $PythonPath = Join-Path $env:USERPROFILE 'Comfyui\.venv\Scripts\python.exe'
  }
}

if ([string]::IsNullOrWhiteSpace($MainPyPath)) {
  if (-not [string]::IsNullOrWhiteSpace($env:COMFYUI_MAIN_PY)) {
    $MainPyPath = $env:COMFYUI_MAIN_PY
  } elseif (-not [string]::IsNullOrWhiteSpace($env:COMFYUI_MAIN)) {
    $MainPyPath = $env:COMFYUI_MAIN
  }
}

if (-not (Test-Path -LiteralPath $PythonPath)) {
  Write-Error "Missing python executable: $PythonPath"
  exit 1
}
if (-not (Test-Path -LiteralPath $MainPyPath)) {
  Write-Error "Missing ComfyUI main.py: $MainPyPath"
  Write-Host "Tip: pass -MainPyPath <path> or set env COMFYUI_MAIN_PY"
  exit 1
}

$argList = @($MainPyPath)

if (-not [string]::IsNullOrWhiteSpace($UserDirectory)) {
  $argList += @('--user-directory', $UserDirectory)
}
if (-not [string]::IsNullOrWhiteSpace($InputDirectory)) {
  $argList += @('--input-directory', $InputDirectory)
}
if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $argList += @('--output-directory', $OutputDirectory)
}
if (-not [string]::IsNullOrWhiteSpace($FrontEndRoot)) {
  $argList += @('--front-end-root', $FrontEndRoot)
}
if (-not [string]::IsNullOrWhiteSpace($BaseDirectory)) {
  $argList += @('--base-directory', $BaseDirectory)
}
if (-not [string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  $argList += @('--database-url', $DatabaseUrl)
}
if (-not [string]::IsNullOrWhiteSpace($ExtraModelPathsConfig)) {
  $argList += @('--extra-model-paths-config', $ExtraModelPathsConfig)
}

$argList += @(
  '--log-stdout',
  '--listen', $Listen,
  '--port', $Port
)

if ($EnableManager) {
  $argList += '--enable-manager'
}

if ($CrossAttention -eq 'pytorch') {
  $argList += '--use-pytorch-cross-attention'
}

if (-not $NoFp16) {
  $argList += @('--force-fp16', '--fp16-vae')
}

if ($ExtraArgs) {
  $argList += $ExtraArgs
}

Write-Host "[ComfyUI] Starting..."
Write-Host "[ComfyUI] Python: $PythonPath"
Write-Host "[ComfyUI] Main:   $MainPyPath"
Write-Host "[ComfyUI] Listen: ${Listen}:${Port}"
Write-Host "[ComfyUI] Args:   $($argList -join ' ')"

& $PythonPath @argList
