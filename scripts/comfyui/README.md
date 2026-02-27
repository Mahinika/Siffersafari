# ComfyUI → Assets (Local Image Generation)

This folder is for generating theme images / mascots locally via ComfyUI.

## Prereqs

- Install and run ComfyUI.
- Default server is `http://127.0.0.1:8188`.

## 1) Export a workflow in API format

In ComfyUI:
- Build a workflow (e.g. txt2img) that outputs images.
- In the **positive prompt** text field, put: `__POSITIVE_PROMPT__`
- In the **negative prompt** text field (if you use one), put: `__NEGATIVE_PROMPT__`
- Export / save as **API format** JSON into:
  - `scripts/comfyui/workflows/txt2img_api.json`

## 2) Generate images into assets

Example:

```bash
dart run scripts/generate_images_comfyui.dart \
  --workflow scripts/comfyui/workflows/txt2img_api.json \
  --prompt "cute friendly space mascot, flat vector, kids app" \
  --negative "scary, gore, realistic" \
  --width 1024 --height 1024 --steps 25 --cfg 6.5 --count 4 \
  --out assets/images/generated
```

If your workflow uses the common ComfyUI nodes, `--width/--height/--steps/--cfg/--seed` will be applied automatically.
If not, the placeholders for prompts still work.
