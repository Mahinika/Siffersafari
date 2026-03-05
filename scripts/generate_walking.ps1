# Generate character_v2 walking animation (8 frames)
# Usage: .\scripts\generate_walking.ps1

param(
    [string]$BaseUrl = "http://127.0.0.1:9000",
    [int]$Seed = 42,
    [int]$Steps = 25,
    [float]$Guidance = 7.0
)

$OutputDir = "artifacts/character_v2_walking"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "Walking animation generation starting..."

$Prompts = @(
    "character_v2 walking left leg forward",
    "character_v2 walking mid-stride",
    "character_v2 walking right leg forward",
    "character_v2 walking opposite stride",
    "character_v2 neutral standing pose",
    "character_v2 walking right facing right",
    "character_v2 walking stride pose",
    "character_v2 final walk position"
)

for ($i = 0; $i -lt 8; $i++) {
    $num = $i.ToString("D3")
    $prompt = $Prompts[$i]
    $output = "$OutputDir/walking_$num.png"
    
    Write-Host "Frame $($i+1): $prompt"
    
    $payload = @{
        prompt = $prompt
        negative_prompt = "bad quality, blurry"
        num_inference_steps = $Steps
        guidance_scale = $Guidance
        seed = $Seed
        width = 512
        height = 512
    }
    
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl/api/text2img" -Method POST -Body ($payload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
        
        if ($resp.data -and $resp.data.Count -gt 0) {
            $imageBytes = [Convert]::FromBase64String($resp.data[0])
            [IO.File]::WriteAllBytes($output, $imageBytes)
            Write-Host "  Saved: $output"
        }
    } catch {
        Write-Host "  Error: $_"
    }
    
    Start-Sleep -Milliseconds 200
}

Write-Host "Done! Frames saved to $OutputDir"
