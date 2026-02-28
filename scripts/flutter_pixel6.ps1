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
$ScriptVersion = 'pixel6-script/v3-deterministic-install'

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

function Get-DebugApkPath {
  return Join-Path $RepoRoot 'build/app/outputs/flutter-apk/app-debug.apk'
}

function Get-PackageInfo([string]$deviceId, [string]$appId) {
  $raw = & adb -s $deviceId shell dumpsys package $appId 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $raw) {
    return $null
  }

  $versionCode = $null
  $versionName = $null
  $lastUpdateTime = $null
  $firstInstallTime = $null

  foreach ($line in $raw) {
    $text = "$line".Trim()
    if (-not $versionCode -and $text -match 'versionCode=([^\s]+)') {
      $versionCode = $matches[1]
      continue
    }
    if (-not $versionName -and $text -match 'versionName=([^\s]+)') {
      $versionName = $matches[1]
      continue
    }
    if (-not $lastUpdateTime -and $text -match '^lastUpdateTime=(.+)$') {
      $lastUpdateTime = $matches[1].Trim()
      continue
    }
    if (-not $firstInstallTime -and $text -match '^firstInstallTime=(.+)$') {
      $firstInstallTime = $matches[1].Trim()
      continue
    }
  }

  return [PSCustomObject]@{
    versionCode = $versionCode
    versionName = $versionName
    lastUpdateTime = $lastUpdateTime
    firstInstallTime = $firstInstallTime
  }
}

$pixelDeviceId = Ensure-Pixel6Device
Write-Host "Använder enhet: $pixelDeviceId (AVD: $PixelAvdName)"
Write-Host "Script: $ScriptVersion"
Write-Host "Repo: $RepoRoot"

$effectiveFlutterArgs = @($FlutterArgs)

if ($Action -eq 'run') {
  Write-Host "Läge: RUN (flutter run + optional logcat dump)"
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

Push-Location $RepoRoot
try {
  Write-Host "Läge: INSTALL (build apk + adb install exact file)"
  $beforeInstall = Get-PackageInfo -deviceId $pixelDeviceId -appId $AppId
  if ($beforeInstall) {
    Write-Host "Före install: version=$($beforeInstall.versionName) code=$($beforeInstall.versionCode) lastUpdateTime=$($beforeInstall.lastUpdateTime)"
  } else {
    Write-Host "Före install: paketet är inte installerat eller kunde inte läsas."
  }

  Write-Host "Bygger debug APK (deterministisk install)..."
  & flutter build apk --debug @effectiveFlutterArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $apkPath = Get-DebugApkPath
  if (-not (Test-Path -LiteralPath $apkPath)) {
    throw "Hittade inte APK efter build: $apkPath"
  }

  $apk = Get-Item -LiteralPath $apkPath
  $apkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $apkPath).Hash

  Write-Host "Installerar exakt APK: $apkPath"
  Write-Host "APK info: size=$($apk.Length) bytes, modified=$($apk.LastWriteTime.ToString('s'))"
  Write-Host "APK sha256: $apkHash"

  # Ignore uninstall failure if app is not already installed.
  & adb -s $pixelDeviceId uninstall $AppId | Out-Null

  & adb -s $pixelDeviceId install -r -t "$apkPath"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  Write-Host "Verifierar installerat paket på enheten..."
  $afterInstall = Get-PackageInfo -deviceId $pixelDeviceId -appId $AppId
  if (-not $afterInstall) {
    throw "Install verification failed: kunde inte läsa package info efter install."
  }

  if (-not $afterInstall.lastUpdateTime -or -not $afterInstall.versionName -or -not $afterInstall.versionCode) {
    throw "Install verification failed: saknar versionName/versionCode/lastUpdateTime efter install."
  }

  if ($beforeInstall -and $beforeInstall.lastUpdateTime -and ($beforeInstall.lastUpdateTime -eq $afterInstall.lastUpdateTime)) {
    throw "Install verification failed: lastUpdateTime ändrades inte. Risk för stale APK/install."
  }

  Write-Host "Efter install: version=$($afterInstall.versionName) code=$($afterInstall.versionCode) lastUpdateTime=$($afterInstall.lastUpdateTime)"
  Write-Host "firstInstallTime=$($afterInstall.firstInstallTime)"
  exit 0
} finally {
  Pop-Location
}
