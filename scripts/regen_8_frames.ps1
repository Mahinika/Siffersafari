# Quick 8-frame regeneration via Easy Diffusion API
# Using direct text2img endpoint

param(
    [string]$BaseUrl = "http://127.0.0.1:9000",
    [string]$OutputDir = "artifacts/animation_preview/ville_walk_regenerated"
)

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$BasePrompt = "ville mascot sprite, same character identity and outfit as input image, jungle explorer boy, full body centered, feet aligned to bottom, front view, 64x64 pixel art style, SNES 16-bit, clean black outlines, limited 16-color palette, sharp pixels, no anti aliasing"
$NegPrompt = "blurry, smooth shading, anti aliasing, gradients, realistic, 3d render, painterly, extra limbs, distorted anatomy, background clutter, text, watermark"

$Poses = @(
    "contact pose, left foot forward",
    "down pose, legs bent, crouched",
    "passing pose, right foot forward",
    "up pose, legs extended, rising",
    "contact returning, weight settling",
    "mid-transition, legs crossing",
    "passing right repeating, stride peak",
    "final recovery, legs relaxing"
)

Write-Host "Starting regeneration of 8 frames..."

for ($i = 0; $i -lt 8; $i++) {
    $Seed = 912411000 + $i
    $Frame = $i.ToString("D3")
    $Pose = $Poses[$i]
    $Prompt = "$BasePrompt, $Pose"
    $OutFile = "$OutputDir/walking_$Frame.png"
    
    $Payload = @{
        prompt = $Prompt
        negative_prompt = $NegPrompt
        num_inference_steps = 24
        guidance_scale = 6.5
        prompt_strength = 0.25
        sampler_name = "dpmpp_2m_karras"
        seed = $Seed
        width = 384
        height = 384
    } | ConvertTo-Json -Depth 3
    
    Write-Host "Frame $($i+1)/8: Seed $Seed | Pose: $Pose"
    
    try {
        $Resp = Invoke-WebRequest "$BaseUrl/api/image" -Method POST -Body $Payload -ContentType "application/json" -TimeoutSec 120 -SkipHttpErrorCheck
        if ($Resp.StatusCode -eq 200) {
            $Json = $Resp.Content | ConvertFrom-Json
            if ($Json.data -and $Json.data.Count -gt 0) {
                $Bytes = [Convert]::FromBase64String($Json.data[0])
                [IO.File]::WriteAllBytes($OutFile, $Bytes)
                $Hash = (Get-FileHash $OutFile -Algorithm SHA256).Hash.Substring(0, 12)
                Write-Host "  OK Saved ($Hash): $OutFile"
            }
        } else {
            Write-Host "  ✗ HTTP $($Resp.StatusCode)"
        }
    } catch {
        Write-Host "  ✗ Error: $_"
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "Verification:"
$Files = Get-ChildItem "$OutputDir/walking_*.png" -ErrorAction SilentlyContinue
$Hashes = $Files | ForEach-Object { (Get-FileHash $_ -Algorithm SHA256).Hash }
$Unique = @($Hashes | Select-Object -Unique).Count
Write-Host "  Total files: $($Files.Count)"
Write-Host "  Unique hashes: $Unique"

if ($Unique -eq 8) {
    Write-Host "  ✓ SUCCESS!" -ForegroundColor Green
} else {
    Write-Host "  ✗ Problem: $Unique unique hashes (expected 8)" -ForegroundColor Red
}
