param(
  [ValidateSet('run', 'install', 'sync')]
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

function Wait-ForAndroidReady([string]$deviceId) {
  Write-Host "Väntar på att enheten ska bli redo (boot + PackageManager)..."

  try {
    & adb -s $deviceId wait-for-device | Out-Null
  } catch {
    throw "Kunde inte ansluta till enheten via adb: $($_.Exception.Message)"
  }

  $bootCompleted = $null
  $timeoutAt = (Get-Date).AddMinutes(4)
  do {
    Start-Sleep -Seconds 2
    try {
      $bootCompleted = (& adb -s $deviceId shell getprop sys.boot_completed 2>$null | Select-Object -First 1)
      $bootCompleted = "$bootCompleted".Trim()
    } catch {
      $bootCompleted = $null
    }
  } while (($bootCompleted -ne '1') -and ((Get-Date) -lt $timeoutAt))

  if ($bootCompleted -ne '1') {
    throw "Enheten rapporterade inte sys.boot_completed=1 inom timeout. (deviceId=$deviceId)"
  }

  $pmReady = $false
  $timeoutAt = (Get-Date).AddMinutes(2)
  do {
    Start-Sleep -Seconds 2
    try {
      $pmOut = & adb -s $deviceId shell pm path android 2>$null
      if ($LASTEXITCODE -eq 0 -and $pmOut) {
        $pmReady = $true
      }
    } catch {
      $pmReady = $false
    }
  } while ((-not $pmReady) -and ((Get-Date) -lt $timeoutAt))

  if (-not $pmReady) {
    throw "PackageManager blev inte redo inom timeout. (deviceId=$deviceId)"
  }
}

function Get-DebugApkPath {
  return Join-Path $RepoRoot 'build/app/outputs/flutter-apk/app-debug.apk'
}

function Get-PackageInfo([string]$deviceId, [string]$appId) {
  try {
    $raw = & adb -s $deviceId shell dumpsys package $appId 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
      return $null
    }
  } catch {
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

function Install-DebugApkAndVerify([string]$deviceId, [string]$appId, [string[]]$flutterArgs) {
  $beforeInstall = Get-PackageInfo -deviceId $deviceId -appId $appId
  if ($beforeInstall) {
    Write-Host "Före install: version=$($beforeInstall.versionName) code=$($beforeInstall.versionCode) lastUpdateTime=$($beforeInstall.lastUpdateTime)"
  } else {
    Write-Host "Före install: paketet är inte installerat eller kunde inte läsas."
  }

  Write-Host "Bygger debug APK (deterministisk install)..."
  & flutter build apk --debug @flutterArgs
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
  & adb -s $deviceId uninstall $appId | Out-Null

  & adb -s $deviceId install -r -t "$apkPath"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  Write-Host "Verifierar installerat paket på enheten..."
  $afterInstall = Get-PackageInfo -deviceId $deviceId -appId $appId
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

  return [PSCustomObject]@{
    beforeInstall = $beforeInstall
    afterInstall = $afterInstall
    apkPath = $apkPath
    apkSha256 = $apkHash
  }
}

$pixelDeviceId = Ensure-Pixel6Device
Wait-ForAndroidReady -deviceId $pixelDeviceId
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
  if ($Action -eq 'install') {
    Write-Host "Läge: INSTALL (build apk + adb install exact file)"
    Install-DebugApkAndVerify -deviceId $pixelDeviceId -appId $AppId -flutterArgs $effectiveFlutterArgs | Out-Null
    exit 0
  }

  if ($Action -eq 'sync') {
    Write-Host "Läge: SYNC (build+install+restart+launch)"
    Install-DebugApkAndVerify -deviceId $pixelDeviceId -appId $AppId -flutterArgs $effectiveFlutterArgs | Out-Null

    Write-Host "Startar om appen för att säkert köra senaste versionen..."
    try {
      & adb -s $pixelDeviceId shell am force-stop $AppId 2>$null | Out-Null
    } catch {
      # Ignore force-stop issues.
    }

    # Launch app without needing to know the exact activity.
    & adb -s $pixelDeviceId shell monkey -p $AppId -c android.intent.category.LAUNCHER 1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Kunde inte starta appen efter sync (monkey exit code=$LASTEXITCODE)."
    }

    Write-Host "SYNC klar: Appen är installerad, omstartad och startad på Pixel_6."
    exit 0
  }

  throw "Okänt Action-läge: $Action"
} finally {
  Pop-Location
}
