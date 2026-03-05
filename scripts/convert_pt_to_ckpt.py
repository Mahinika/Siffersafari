"""
Convert .pt model file to .ckpt format for Easy Diffusion
"""
import torch
import sys
import os

def convert_pt_to_ckpt(pt_path, ckpt_path):
    """Convert PyTorch .pt model to .ckpt checkpoint"""
    print(f"Loading model from: {pt_path}")
    
    # Load the .pt file
    state_dict = torch.load(pt_path, map_location='cpu')
    
    print(f"Model loaded successfully. Keys: {len(state_dict.keys()) if isinstance(state_dict, dict) else 'N/A'}")
    
    # Save as .ckpt (which is just a PyTorch checkpoint)
    print(f"Saving checkpoint to: {ckpt_path}")
    torch.save(state_dict, ckpt_path)
    
    print("✓ Conversion complete!")
    return True

if __name__ == "__main__":
    # Paths
    models_dir = r"D:\Tools\EasyDiffusion\models\stable-diffusion"
    pt_file = os.path.join(models_dir, "pixel_art_diffusion_soft_256.pt")
    ckpt_file = os.path.join(models_dir, "pixel_art_diffusion_soft_256.ckpt")
    
    if not os.path.exists(pt_file):
        print(f"ERROR: Source file not found: {pt_file}")
        sys.exit(1)
    
    try:
        convert_pt_to_ckpt(pt_file, ckpt_file)
        print(f"\n✓ Checkpoint saved: {ckpt_file}")
        print(f"File size: {os.path.getsize(ckpt_file) / (1024*1024):.1f} MB")
    except Exception as e:
        print(f"ERROR: Conversion failed: {e}")
        sys.exit(1)
