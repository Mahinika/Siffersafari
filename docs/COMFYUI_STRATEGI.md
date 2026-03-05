# ComfyUI-strategi (Siffersafari)

> För praktiska kommandon (starta ComfyUI, benchmark, hur man kör scripts/workflows): se `scripts/comfyui/README.md`.

Mål: generera barnvänliga (6–12), tydliga och konsekventa assets till spelet, främst:
- Tema-bakgrunder (Home/menyer)
- Quest-hero (större figur/illustration)
- Karaktär (PNG med transparens, funkar i UI i olika storlekar)

Vi vill optimera för:
- Konsekvent stil mellan bilder och mellan teman
- En karaktär som “är samma person” i flera variationer
- Ren transparens (utan "hål" i motivet och utan kvarvarande bakgrund)
- Reproducerbarhet (seed + workflow + prompts)

---

## Nuläge i repo

### API-klient
- `scripts/generate_images_comfyui.dart` skickar workflow (API-json) till ComfyUI `/prompt`, pollar `/history/{promptId}` och laddar ner bilder via `/view`.
- Stöd för placeholders:
  - `__POSITIVE_PROMPT__`
  - `__NEGATIVE_PROMPT__`
  - `__INIT_IMAGE__` (img2img)

### Workflows
- `scripts/comfyui/workflows/txt2img_api.json`: SDXL base + refiner (två pass)
- `scripts/comfyui/workflows/img2img_color_api.json`: SDXL img2img (initbild + denoise)

---

## Nyckelinsikt: vad som brukar gå fel (och hur vi undviker det)

1) **”Samma karaktär” driftar**
- Txt2img ger ofta olika ansikte/kläder mellan generationer.
- Lösning: använd referens-baserad styrning (IP-Adapter) eller kontrollerande hints (ControlNet) eller img2img med låg denoise.

1b) **Animation: “mer rörelse” kan ge mer drift**
- Om vi höjer `denoise` för att få tydligare pose (t.ex. spring) driftar ofta hatt/kläder/färger snabbt, särskilt i pixel-stil.
- Lösning: håll `denoise` låg/medel och styr pose separat (t.ex. OpenPose/ControlNet). Lås identitet med init-bild och helst IP-Adapter.
- Praktiskt i repo: använd `scripts/generate_character_v2_animation_frames.ps1` med `-StableSeed` (samma seed över alla frames) och gör snabb preview med `scripts/preview_animation_gif.dart`.

2) **Transparens blir halvdålig**
- Corner flood-fill funkar sämre om bakgrunden har mycket struktur, gradient eller om motivet har glapp i outline.
- Lösning: designa workflow så att bakgrunden blir *avsiktligt enkel* (t.ex. solid chroma) eller producera en mask (segmentation/SAM) i workflow.

3) **Karaktär kommer i ”sheet” (två figurer)**
- Ofta pga prompts som antyder ”character sheet” eller modellens bias.
- Lösning: styr prompt hårdare (”single character, centered, full body, one subject”) och/eller använd bbox/segmentering för att extrahera största komponenten.

4) **Workflow/validering strular pga miljöskillnader**
- Samma workflow kan validera olika beroende på vilka samplers/noder som finns i din ComfyUI-install.
- Lösning: håll dig till verifierat stödda sampler-namn (och undvik att “gissa” nya) samt föredra enklare noder i batch-flöden.

---

## Rekommenderad pipeline (3 nivåer)

### Nivå A — Stabil baseline

Syfte: snabbt få fram användbara assets med befintlig setup.

1. **Generera** (txt2img eller img2img)
   - Bakgrund: txt2img funkar bra
   - Karaktär: börja med img2img från en "kanon-bild" och håll `denoise` låg (0.25–0.45)

2. **Transparens**
   - Bygg in mask i ComfyUI-workflow (semantic segmentation eller SAM) för ren alpha
   - Alternativt: använd chroma-key med solid bakgrund

3. **QA**
   - Manuell granskning + preview i appen
   - Verifiera att alpha ser bra ut (inga hål, inga kvarvarande bakgrundsrester)

### Nivå B — Konsekvent karaktär (rekommenderas)
Syfte: göra “samma person” i många variationer/teman.

**IP-Adapter**
- Idé: ge ComfyUI en referensbild på karaktären och låt IP-Adapter styra innehåll/stil.
- Resultat: mycket bättre identitet/kläder/ansikte över flera generationer.

Praktiskt upplägg:
1. Välj en “master reference” (t.ex. `assets/images/themes/jungle/character_v2.png` eller en bättre råbild innan friläggning).
2. Skapa ett nytt workflow (API-json) som:
   - laddar checkpoint
   - laddar referensbild
   - använder IP-Adapter-nod (weight ~0.6–0.9 som start)
   - kombinerar med prompt (för pose/uttryck/rekvisita)

---

## Animation (idle/jump/run/wave): rekommenderat arbetssätt

Mål: få **tydlig rörelse** utan att karaktären byter outfit/hatttyp mellan frames.

1) Generera frames (utan emulator)
- Script: `scripts/generate_character_v2_animation_frames.ps1`
- Rekommenderad start:
  - `-Anim run -Frames 8 -StableSeed`
  - ev. `-ChainInit` om du behöver mer sammanhängande loop (men håll koll på artefakt-ackumulering)
  - håll `-Denoise` låg/medel (t.ex. 0.25–0.45) om identiteten driftar

2) Preview + inspektion
   - Preview GIF: se `scripts/comfyui/README.md` för workflow-info
   - Inspektera timing och slingning visuellt

3) När prompt inte räcker
- Om benen/armarna inte “läser” som spring: lägg till pose-signal (OpenPose/ControlNet) i workflow istället för att bara höja `denoise`.

Tips: använd spritesheet-workflows för snabb visuell granskning (t.ex. 4 frames @ 256px, 2×2) men exportera i slutändan **1 PNG per frame** till app-assets.


### Nivå C — Riktigt bra alpha (mask i workflow)
Syfte: slippa gissa bakgrund via hörn-floodfill.

Alternativ 1: **Semantic segmentation** (t.ex. OneFormer/UniFormer via CNAux)
- Workflow producerar en mask (”person/foreground”) och applicerar den som alpha.

Alternativ 2: **SAM/MobileSAM**
- Bra om motivet är tydligt avgränsat.

Med mask i workflow kan vi:
- få ren alpha direkt
- undvika ”transparenta hål” genom att postprocessa masken (dilate/erode/blur) innan compositing

---

## Prompt-regler som funkar för oss (kids-app + tydlig UI)

För karaktär:
- Positive (exempel):
  - "cute friendly jungle explorer kid, full body, centered, bold outline, simple shapes, high contrast, clean silhouette, cartoon, no text"
- Negative (exempel):
  - "scary, creepy, gore, realistic, blurry, noisy, text, watermark, logo, multiple characters, character sheet"

Tips:
- Lägg "single character" + "one subject" + "centered" tidigt.
- Lägg "no background"/"solid background" om vi ska flood-filla bort bakgrund.

---

## Felsökning (3 steg)
1. **Ping** servern (rätt baseUrl/port).
2. **Workflow**: kör ett minimalt workflow och se att output faktiskt produceras.
3. **Output**: verifiera var ComfyUI sparar, och att vår nedladdning/postprocess hittar filerna.

---

## Konkreta nästa steg (för att nå ‘det vi vill’)

1) **Bestäm “kanon-karaktär”**
- En (1) masterbild som allt annat baseras på.

2) **Lägg till ett nytt workflow för “character_from_reference”**
- Antingen img2img-låg-denoise eller IP-Adapter.

3) **Bygg en liten “batch + score” loop**
- Generera 12–24 kandidater.
- Kör alpha-analys + enkla heuristiker.
- Välj topp 3 manuellt.

4) **När det sitter: byt till mask-baserad alpha i workflow**
- Då blir transparens stabil, och `make_background_transparent.dart` blir backup istället för huvudspår.

---

## Hög ROI (börja här)

### 1) Standardisera anslutningen till ComfyUI

Vi kör ComfyUI på `http://127.0.0.1:8000`. Scriptet `generate_images_comfyui.dart` använder nu som default:
- `COMFYUI_SERVER`/`COMFYUI_URL` om satt
- annars `http://127.0.0.1:8000`

Det betyder att vi nästan alltid slipper skriva `--server ...`.

### 2) Batcha “samma karaktär” via img2img (låg denoise)

Det här ger bäst payoff per minut.

Exempel-recept (12 variationer från en kanonbild):

1. Välj en kanonbild (init): `assets/images/themes/jungle/character_v2.png`

2. Generera batch via `scripts/generate_images_comfyui.dart`:
   - workflow: `img2img_color_api.json`
   - init: kanonbild
   - prompt: "cute friendly jungle explorer kid, full body, centered, bold outline"
   - negative: "scary, gore, text, multiple characters"
   - denoise: 0.35, cfg: 6.5, steps: 28, count: 12

3. Granska visuellt och välj bästa
  - plocka 3 toppkandidater och kör `dart run scripts/analyze_image_alpha.dart <fil.png>` för djupcheck.

### 3) När vi gör många assets: investera i IP-Adapter

Om vi ska göra 50–200+ bilder med samma karaktär är IP-Adapter nästa högsta ROI:
- Mindre “identitetsdrift” än ren txt2img/img2img
- Färre omtag
- Mer kontroll (pose/uttryck) utan att tappa vem det är

Det kräver custom nodes (lättast via ComfyUI-Manager) + några modeller i rätt mappar.

---

## Pose-pack (Val A): “fulla assets” för animation

Mål: generera ett litet paket med poser (PNG) från en *master reference* (`character_v2`) som du kan använda för enklare animationer (bildbyte + små UI-animationer).

### Baslinje (funkar utan nya ComfyUI-plugins)

Det här använder vår befintliga img2img-workflow och håller identiteten hyfsat bra via låg `denoise`.

- Kör pose-pack via scriptet `scripts/generate_character_v2_pose_pack.ps1`.
  - Exakta kommandon (inkl. flaggor) finns i `scripts/comfyui/README.md`.

Output hamnar i `artifacts/comfyui/pose_pack_YYYYMMDD_HHMMSS/` med en mapp per pose.

Tips om kvalitet:
- Om identiteten driftar: sänk `-Denoise` (t.ex. 0.25–0.35) och öka `-Steps`.
- Om friläggningen blir dålig: se till att prompten ger *solid light background*.

### Exportera ditt workflow till repo (så scripts kan använda det)

Om du har byggt ett bättre workflow i ComfyUI (t.ex. med IP-Adapter + OpenPose), exportera det i **API-format** direkt in i repo så kan våra scripts köra det.

1) I ComfyUI: `Workflow → Save (API Format)`
2) Spara filen som:
- `scripts/comfyui/workflows/character_v2_pose_pack_api.json`

Pose-pack-scriptet väljer automatiskt den filen om den finns. Annars faller det tillbaka till `img2img_color_api.json`.

Om du vill peka ut en annan fil explicit:
- Se `scripts/comfyui/README.md` (Pose-pack) för exempel på hur du pekar ut workflow explicit.

### Bästa sätt (rekommenderas): IP-Adapter + (ev) OpenPose

För att få *samma karaktär* över många poser med mindre drift är det standard att använda:
- **IP-Adapter** (referensbild → stabil identitet/stil)
- **ControlNet OpenPose** (pose-hint → stabil kropp/armar)

Det kräver att du installerar custom nodes + laddar ner modeller.

---

## Installera det som saknas (när du inte har ComfyUI-Manager)

### 1) Installera ComfyUI-Manager (rekommenderas)

Se `scripts/comfyui/README.md` för exakta kommandon (custom_nodes + git clone) och felsökning.

Om du saknar Git på Windows: installera Git (standardinstall) först.

### 2) IP-Adapter (för stabil identitet)

Se `scripts/comfyui/README.md` för exakta kommandon (install av custom nodes) och vilka modellmappar som används.

Ladda ner modeller (SDXL):
- CLIP-Vision encoder till `ComfyUI/models/clip_vision/` (följ filnamn/krav i repo-readme för IPAdapter).
- IP-Adapter SDXL weights till `ComfyUI/models/ipadapter/` (följ filnamn/krav i repo-readme för IPAdapter).

### 3) OpenPose-preprocessor + ControlNet OpenPose SDXL (för stabil pose)

Se `scripts/comfyui/README.md` för exakta kommandon (install av preprocessors) samt notiser kring dependencies.

Ladda ner ControlNet OpenPose för SDXL (viktigt: SDXL-modell):
- Exempel: `thibaud/controlnet-openpose-sdxl-1.0` eller `xinsir/controlnet-openpose-sdxl-1.0` (safetensors).
- Placera i den ControlNet-modellmapp som din ComfyUI-installation använder.

Notis: OpenPose-preprocessor laddar ofta ner annotator-modeller första gången (från HuggingFace). Om du kör offline behöver de laddas ner manuellt.
