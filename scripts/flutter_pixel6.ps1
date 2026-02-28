param(
  [ValidateSet('run', 'install')]
  [string]$Action = 'run',
  [string[]]$FlutterArgs = @(),
  [switch]$ClearLogcatBeforeRun,
  [switch]$DumpLogcatOnLostConnection,
  [switch]$DumpLogcatAfterRun,
  [string]$LogOutputDir = 'build/logs'
)

$ErrorActionPreference = 'Stop'
$PixelAvdName = 'Pixel_6'
$AppId = 'com.example.math_game_app'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Ensure-Directory([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Get-Pixel6DeviceId {
  $lines = & adb devices
  $deviceIds = @()

  foreach ($line in $lines) {
    if ($line -match '^([^\s]+)\s+device$') {
      $deviceIds += $matches[1]
    }
  }

  foreach ($id in $deviceIds) {
    if ($id -like 'emulator-*') {
      try {
        $rawNameOutput = & adb -s $id emu avd name 2>$null
        $avdName = $null
        foreach ($line in $rawNameOutput) {
          $candidate = "$line".Trim()
          if ($candidate -and $candidate -ne 'OK') {
            $avdName = $candidate
            break
          }
        }
        if ($avdName -eq $PixelAvdName) {
          return $id
        }
      } catch {
      }
    }
  }

  return $null
}

function Ensure-Pixel6Device {
  $deviceId = Get-Pixel6DeviceId
  if ($deviceId) {
    return $deviceId
  }

  Write-Host "Pixel_6 körs inte. Startar emulatorn..."
  & flutter emulators --launch $PixelAvdName | Out-Host

  $timeoutAt = (Get-Date).AddMinutes(3)
  do {
    Start-Sleep -Seconds 2
    $deviceId = Get-Pixel6DeviceId
  } while ((-not $deviceId) -and ((Get-Date) -lt $timeoutAt))

  if (-not $deviceId) {
    throw "Kunde inte hitta en aktiv Pixel_6-emulator inom timeout."
  }

  return $deviceId
}

$pixelDeviceId = Ensure-Pixel6Device
Write-Host "Använder enhet: $pixelDeviceId (AVD: $PixelAvdName)"

$effectiveFlutterArgs = @($FlutterArgs)

if ($Action -eq 'run') {
  if ($ClearLogcatBeforeRun) {
    try {
      & adb -s $pixelDeviceId logcat -c | Out-Null
    } catch {
      # Ignore logcat clear issues; don't block running.
    }
  }

  $resolvedLogOutputDir = $LogOutputDir
  if (-not [System.IO.Path]::IsPathRooted($resolvedLogOutputDir)) {
    $resolvedLogOutputDir = Join-Path $RepoRoot $resolvedLogOutputDir
  }

  Ensure-Directory -path $resolvedLogOutputDir
  $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $runLogPath = Join-Path $resolvedLogOutputDir "flutter_run_${timestamp}.log"

  "[${timestamp}] flutter run on $pixelDeviceId" | Out-File -FilePath $runLogPath -Encoding utf8

  & flutter run -d $pixelDeviceId @effectiveFlutterArgs 2>&1 | Tee-Object -FilePath $runLogPath -Append

  $exitCode = $LASTEXITCODE

  $shouldDumpLogcat = $DumpLogcatAfterRun

  if ($DumpLogcatOnLostConnection) {
    $lostConnection = $false
    if (Test-Path -LiteralPath $runLogPath) {
      $lostConnection = Select-String -Path $runLogPath -Pattern 'Lost connection to device\.' -Quiet
    }
    if ($lostConnection) { $shouldDumpLogcat = $true }
  }

  if ($shouldDumpLogcat) {
    $logcatPath = Join-Path $resolvedLogOutputDir "logcat_${timestamp}.txt"
    try {
      & adb -s $pixelDeviceId logcat -d -v time 2>&1 | Out-File -FilePath $logcatPath -Encoding utf8
      Write-Host "\n[logcat] Sparade logcat till: $logcatPath"
    } catch {
      Write-Warning "Kunde inte dumpa logcat: $($_.Exception.Message)"
    }
  }

  exit $exitCode
}

& flutter install -d $pixelDeviceId --debug @effectiveFlutterArgs
exit $LASTEXITCODE
