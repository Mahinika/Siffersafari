param(
  [ValidateSet('run', 'install')]
  [string]$Action = 'run',
  [string[]]$FlutterArgs = @()
)

$ErrorActionPreference = 'Stop'
$PixelAvdName = 'Pixel_6'

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

if ($Action -eq 'run') {
  & flutter run -d $pixelDeviceId @FlutterArgs
  exit $LASTEXITCODE
}

& flutter install -d $pixelDeviceId --debug @FlutterArgs
exit $LASTEXITCODE
