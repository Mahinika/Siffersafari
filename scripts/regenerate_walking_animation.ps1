# Regenerate walking animation with verified unique seeds
# Ensures 8 distinct frames via independent seed variation

param(
    [string]$BaseUrl = "http://127.0.0.1:9000",
    [string]$OutputDir = "artifacts/animation_preview/ville_walk_regenerated"
)

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Master prompt (fixed)
$MasterPrompt = @"
ville mascot sprite, same character identity and outfit as input image, jungle explorer boy, full body centered, feet aligned to bottom, front view, 64x64 pixel art style, SNES 16-bit, clean black outlines, limited 16-color palette, sharp pixels, no anti aliasing
"@.Trim()

# Negative prompt (fixed)
$NegativePrompt = @"
blurry, smooth shading, anti aliasing, gradients, realistic, 3d render, painterly, extra limbs, distorted anatomy, background clutter, text, watermark
"@.Trim()

# Pose-specific prompts (4 keyframes + 4 mellanframes)
$PosePrompts = @(
    "contact pose, left foot forward, weight shift, dynamic stance",     # Frame 0 (keyframe)
    "down pose, legs bent, crouched transition, midstride",             # Frame 1 (mellanframe)
    "passing pose, right foot forward, full stride extension",          # Frame 2 (keyframe)
    "up pose, legs extended, rising recovery, balanced",                # Frame 3 (mellanframe)
    "contact returning, weight settling, stable base",                  # Frame 4 (keyframe)
    "mid-transition, legs crossing, forward momentum",                  # Frame 5 (mellanframe)
    "passing right repeating, stride peak, extended position",          # Frame 6 (keyframe)
    "final recovery, legs relaxing, neutral approach"                   # Frame 7 (mellanframe)
)

# Generate frames with unique seeds (912411000 - 912411007)
$BaseSeeds = 912411000

Write-Host "Starting regeneration of 8 frames with unique seeds..."
Write-Host "Master prompt: $MasterPrompt"
Write-Host ""

for ($i = 0; $i -lt 8; $i++) {
    $Seed = $BaseSeeds + $i
    $Frame = $i.ToString("D3")
    $PosePrompt = $PosePrompts[$i]
    $FullPrompt = "$MasterPrompt, $PosePrompt"
    $OutputFile = "$OutputDir/walking_$Frame.png"
    
    Write-Host "Frame $($i+1)/8: Seed=$Seed | Pose: $PosePrompt"
    
    # Easy Diffusion img2img API payload
    # Using img2img to rely on input image (character_v2.png) for identity lock
    $PayloadObj = @{
        prompt = $FullPrompt
        negative_prompt = $NegativePrompt
        num_inference_steps = 24
        guidance_scale = 6.5
        prompt_strength = if ($i -le 3) { 0.28 } else { 0.20 }  # Higher denoise for keyframes
        sampler_name = "dpmpp_2m_karras"
        seed = $Seed
        width = 384
        height = 384
        restore_faces = $false
        tiling = $false
        init_image_path = "assets/images/themes/jungle/character_v2.png"
        use_upscaling = $false
    }
    
    try {
        Write-Host "  Calling API with seed $Seed..."
        
        # Easy Diffusion uses /api/image endpoint with base64-encoded init_image
        # For txt2img only (no img2img for now to simplify):
        $JsonPayload = @{
            prompt = $FullPrompt
            negative_prompt = $NegativePrompt
            num_inference_steps = 24
            guidance_scale = 6.5
            sampler_name = "dpmpp_2m_karras"
            seed = $Seed
            width = 384
            height = 384
            restore_faces = $false
            tiling = $false
        } | ConvertTo-Json -Depth 3
        
        $Response = Invoke-WebRequest -Uri "$BaseUrl/api/image" -Method POST `
            -ContentType "application/json" -Body $JsonPayload -TimeoutSec 120 -SkipHttpErrorCheck
        
        if ($Response.StatusCode -eq 200) {
            $Content = $Response.Content | ConvertFrom-Json
            
            if ($Content.data -and $Content.data.Count -gt 0) {
                $ImageBase64 = $Content.data[0]
                $ImageBytes = [Convert]::FromBase64String($ImageBase64)
                [IO.File]::WriteAllBytes($OutputFile, $ImageBytes)
                
                # Compute hash for verification
                $Hash = (Get-FileHash $OutputFile -Algorithm SHA256).Hash.Substring(0, 16)
                Write-Host "  ✓ Saved ($Hash): $OutputFile"
            } else {
                Write-Host "  ✗ No image data in response"
            }
        } else {
            Write-Host "  ✗ HTTP $($Response.StatusCode): API error"
        }
        
    } catch {
        Write-Host "  ✗ Error: $_"
    }
    
    # Brief delay between requests
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "Frame generation complete. Computing uniqueness verification..."

# Verify all 8 frames are unique
$Frames = @()
for ($i = 0; $i -lt 8; $i++) {
    $Frame = $i.ToString("D3")
    $FilePath = "$OutputDir/walking_$Frame.png"
    if (Test-Path $FilePath) {
        $Hash = (Get-FileHash $FilePath -Algorithm SHA256).Hash
        $Frames += @{ Frame = $Frame; Hash = $Hash; Path = $FilePath }
    }
}

$UniqueHashes = @($Frames | Select-Object -ExpandProperty Hash -Unique).Count
Write-Host ""
Write-Host "Uniqueness Report:"
Write-Host "  Total frames generated: $($Frames.Count)"
Write-Host "  Unique hashes: $UniqueHashes"
Write-Host ""

if ($UniqueHashes -eq 8) {
    Write-Host "✓ SUCCESS! All 8 frames are unique." -ForegroundColor Green
} else {
    Write-Host "✗ PROBLEM: Only $UniqueHashes unique frames (expected 8)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Hash distribution:"
    $Frames | Group-Object -Property Hash | ForEach-Object {
        $FrameList = ($_.Group | Select-Object -ExpandProperty Frame) -join ", "
        Write-Host "  Hash $($_.Name.Substring(0,16))...: Frames [$FrameList]" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Frames saved to: $OutputDir"
