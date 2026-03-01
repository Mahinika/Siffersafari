# Asset-plan (ComfyUI) – MVP som gör appen tydligt bättre

Appen har redan stöd för temabaserade bakgrunder via `assets/images/themes/<theme>/background.png`. För att nya assets ska ge direkt effekt rekommenderas ett **minimalt theme-pack** som vi itererar på (bakgrunder först, sedan badges).

## 1) Prioritet (gör mest skillnad först)

### A. Theme-bakgrunder (högst ROI)
- **Syfte:** Gör Home/Quiz/Results visuellt “speligt” direkt.
- **Format:** JPG eller PNG (ingen transparens behövs).
- **Storlek (SDXL-säkert):** `1024x1536` (portrait) eller `1152x1536`.
- **Mängd (MVP):** 4 per tema (space/jungle).
- **Målplats:**
  - `assets/images/themes/space/`
  - `assets/images/themes/jungle/`

Rekommenderad naming när du väljer “bästa” bilden:
- `assets/images/themes/space/background.png`
- `assets/images/themes/jungle/background.png`

(Övriga varianter kan ligga kvar med scriptets filnamn.)

### B. Badges/achievements (näst högst ROI)
- **Syfte:** Ger belöningskänsla i Resultat/achievements.
- **Format:** PNG.
- **Storlek:** `512x512`.
- **Mängd (MVP):** 12–20.
- **Målplats:** `assets/images/badges/` (skapa mappen om den saknas).

### C. Dekorationer (stjärnor/blad) för UI
- **Syfte:** Små visuella detaljer i kort/dialoger.
- **Format:** PNG.
- **Storlek:** `512x512`.
- **Mängd (MVP):** 8 per tema.
- **Målplats:** `assets/images/themes/<theme>/decorations/`.

> Karaktärer/mascots med transparens är ofta lite mer pill (alpha / friläggning). Spara dem till efter att bakgrunder + badges sitter.

## 2) Förutsättningar (en gång)

1. Starta ComfyUI och verifiera att det svarar på: `http://127.0.0.1:8188`.
2. Se till att SDXL **base** finns i `ComfyUI/models/checkpoints/` (t.ex. `sd_xl_base_1.0_0.9vae.safetensors`).
3. Workflow ska vara exporterad i **API format**: [scripts/comfyui/workflows/txt2img_api.json](scripts/comfyui/workflows/txt2img_api.json)
4. I workflow: lägg in placeholders i text-noder innan export:
   - `__POSITIVE_PROMPT__`
   - `__NEGATIVE_PROMPT__`

## 3) Exakta kommandon (copy/paste)

### A) Space-bakgrunder (4 st)

Kör från repo-root:

`dart run scripts/generate_images_comfyui.dart --workflow scripts/comfyui/workflows/txt2img_api.json --out assets/images/themes/space --count 4 --width 1024 --height 1536 --steps 28 --cfg 6.0 --prompt "kids game background, friendly space theme, soft gradient nebula, cute planets and stars, 2D illustration, clean shapes, no text" --negative "text, logo, watermark, photo, realistic, creepy, dark horror, clutter, blurry, lowres"`

### B) Jungle-bakgrunder (4 st)

`dart run scripts/generate_images_comfyui.dart --workflow scripts/comfyui/workflows/txt2img_api.json --out assets/images/themes/jungle --count 4 --width 1024 --height 1536 --steps 28 --cfg 6.0 --prompt "kids game background, friendly jungle theme, lush leaves, warm sunlight, simple 2D illustration, clean shapes, no text" --negative "text, logo, watermark, photo, realistic, creepy, dark horror, clutter, blurry, lowres"`

### C) Badges (12 st)

Skapa mappen om den inte finns: `assets/images/badges/`

`dart run scripts/generate_images_comfyui.dart --workflow scripts/comfyui/workflows/txt2img_api.json --out assets/images/badges --count 12 --width 512 --height 512 --steps 28 --cfg 6.5 --prompt "achievement badge icon, kids game, bold simple shape, centered, high contrast, 2D vector style, clean outline, no text" --negative "text, logo, watermark, photo, realistic, messy details, blurry, lowres"`

## 4) Välj “final” filer

- Titta igenom output och välj en favorit per tema.
- Byt namn på favoriterna till:
  - `assets/images/themes/space/background.png`
  - `assets/images/themes/jungle/background.png`

## 5) Nästa steg (när assets finns)

Säg till så kan jag koppla in bakgrundsbilden i Home/Quiz/Results med fallback till nuvarande färger (så blir ingen risk att appen kraschar om en bild saknas).
