$BaseUrl = "http://127.0.0.1:9000"
$OutDir = "artifacts/animation_preview/ville_walk_regenerated"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$BasePrompt = "ville mascot sprite, same character identity and outfit as input image, jungle explorer boy, full body centered, feet aligned to bottom, front view, 64x64 pixel art style, SNES 16-bit, clean black outlines, limited 16-color palette, sharp pixels, no anti aliasing"
$NegPrompt = "blurry, smooth shading, anti aliasing, gradients, realistic, 3d render, painterly, extra limbs, distorted anatomy, background clutter, text, watermark"

$Poses = @(
    "contact pose, left foot forward"
    "down pose, legs bent"
    "passing pose, right foot forward"
    "up pose, legs extended"
    "contact returning"
    "mid-transition, legs crossing"
    "passing right repeating"
    "final recovery"
)

Write-Host "Regenerating 8 frames..."

for ($i = 0; $i -lt 8; $i++) {
    $Seed = 912411000 + $i
    $Frame = $i.ToString("D3")
    $Pose = $Poses[$i]
    $Prompt = "$BasePrompt, $Pose"
    $OutFile = "$OutDir/walking_$Frame.png"
    
    Write-Host "Frame $($i+1): Seed $Seed"
    
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
    
    try {
        $Resp = Invoke-WebRequest "$BaseUrl/api/image" -Method POST -Body $Payload -ContentType "application/json" -TimeoutSec 120
        if ($Resp.StatusCode -eq 200) {
            $Json = $Resp.Content | ConvertFrom-Json
            if ($Json.data -and $Json.data[0]) {
                $Bytes = [Convert]::FromBase64String($Json.data[0])
                [IO.File]::WriteAllBytes($OutFile, $Bytes)
                Write-Host "  OK saved"
            }
        }
    } catch {
        Write-Host "  Error: $_"
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host "Done"
