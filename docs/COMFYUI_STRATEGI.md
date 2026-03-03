# ComfyUI-strategi (Multiplikation)

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
- `scripts/comfyui/workflows/txt2img_api.json`: SDXL base + refiner (två pass).
- `scripts/comfyui/workflows/img2img_color_api.json`: SDXL img2img (initbild + denoise).

### Postprocess/QA
- `scripts/make_background_transparent.dart`: hörn-baserad bakgrundsborttagning (fungerar bäst om bakgrunden är relativt platt/solid).
- `scripts/analyze_image_alpha.dart`: objektiv alpha-check (transparent/semi/opaque, edge non-transparent, bbox + hole detection).
- `scripts/analyze_comfyui_batch.dart`: batchdiagnostik för en hel mapp.
- `scripts/crop_character_sheet.dart`: beskär vänster/höger-panel när ComfyUI råkar generera två karaktärer i en bild.

---

## Nyckelinsikt: vad som brukar gå fel (och hur vi undviker det)

1) **”Samma karaktär” driftar**
- Txt2img ger ofta olika ansikte/kläder mellan generationer.
- Lösning: använd referens-baserad styrning (IP-Adapter) eller kontrollerande hints (ControlNet) eller img2img med låg denoise.

2) **Transparens blir halvdålig**
- Corner flood-fill funkar sämre om bakgrunden har mycket struktur, gradient eller om motivet har glapp i outline.
- Lösning: designa workflow så att bakgrunden blir *avsiktligt enkel* (t.ex. solid chroma) eller producera en mask (segmentation/SAM) i workflow.

3) **Karaktär kommer i ”sheet” (två figurer)**
- Ofta pga prompts som antyder ”character sheet” eller modellens bias.
- Lösning: styr prompt hårdare (”single character, centered, full body, one subject”) och/eller använd bbox/segmentering för att extrahera största komponenten.

---

## Rekommenderad pipeline (3 nivåer)

### Nivå A — Stabil baseline (ingen ny ComfyUI-install)
Syfte: snabbt få fram användbara assets med det vi redan har.

1. **Generera** (txt2img eller img2img)
   - Bakgrund: txt2img funkar bra.
   - Karaktär: börja med img2img från en “kanon-bild” (en enda master-karaktär) och håll `denoise` låg (t.ex. 0.25–0.45).

2. **Gör transparens**
   - Kör `scripts/make_background_transparent.dart`.
   - Viktigt: se till att ComfyUI-bilden har en bakgrund som är *så platt som möjligt*.

3. **QA**
   - Kör `scripts/analyze_image_alpha.dart` på slut-PNG.
   - Röd flagg:
     - väldigt låg transparensandel (bakgrund kvar)
     - många edge-nontransparent pixlar (motiv ”läcker” ut till kanten)
     - hole detection varnar (genomskinliga hål inne i motivet)


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

Det här ger bäst payoff per minut utan att installera nya custom nodes.

Exempel (12 variationer från en kanonbild):

1. Välj en kanonbild (init):
  - t.ex. `assets/images/themes/jungle/character_v2.png` (eller en råbild utan alpha om du har en bättre).

2. Generera batch:
  - `dart run scripts/generate_images_comfyui.dart --workflow scripts/comfyui/workflows/img2img_color_api.json --init assets/images/themes/jungle/character_v2.png --prompt "cute friendly jungle explorer kid, full body, centered, bold outline, simple shapes, clean silhouette, cartoon, solid background" --negative "scary, creepy, gore, realistic, text, watermark, logo, multiple characters, character sheet" --denoise 0.35 --cfg 6.5 --steps 28 --count 12 --out build/tmp/char_batch`

3. Kör QA snabbt:
  - `dart run scripts/analyze_comfyui_batch.dart build/tmp/char_batch`
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

- Kör pose-pack scriptet:
  - `powershell -ExecutionPolicy Bypass -File scripts/generate_character_v2_pose_pack.ps1 -AlphaAll`

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
- `powershell -ExecutionPolicy Bypass -File scripts/generate_character_v2_pose_pack.ps1 -Workflow <din_workflow.json> -AlphaAll`

### Bästa sätt (rekommenderas): IP-Adapter + (ev) OpenPose

För att få *samma karaktär* över många poser med mindre drift är det standard att använda:
- **IP-Adapter** (referensbild → stabil identitet/stil)
- **ControlNet OpenPose** (pose-hint → stabil kropp/armar)

Det kräver att du installerar custom nodes + laddar ner modeller.

---

## Installera det som saknas (när du inte har ComfyUI-Manager)

### 1) Installera ComfyUI-Manager (rekommenderas)

I din ComfyUI-mapp:
- Gå till `ComfyUI/custom_nodes/`
- Kör:
  - `git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager`
- Starta om ComfyUI

Om du saknar Git på Windows: installera Git (standardinstall) först.

### 2) IP-Adapter (för stabil identitet)

Installera custom nodes:
- `ComfyUI/custom_nodes/`:
  - `git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus`
- Starta om ComfyUI

Ladda ner modeller (SDXL):
- CLIP-Vision encoder till `ComfyUI/models/clip_vision/` (följ filnamn/krav i repo-readme för IPAdapter).
- IP-Adapter SDXL weights till `ComfyUI/models/ipadapter/` (följ filnamn/krav i repo-readme för IPAdapter).

### 3) OpenPose-preprocessor + ControlNet OpenPose SDXL (för stabil pose)

Installera preprocessors:
- `ComfyUI/custom_nodes/`:
  - `git clone https://github.com/Fannovel16/comfyui_controlnet_aux/`
- Installera dependencies enligt deras README (pip/requirements) och starta om ComfyUI.

Ladda ner ControlNet OpenPose för SDXL (viktigt: SDXL-modell):
- Exempel: `thibaud/controlnet-openpose-sdxl-1.0` eller `xinsir/controlnet-openpose-sdxl-1.0` (safetensors).
- Placera i den ControlNet-modellmapp som din ComfyUI-installation använder.

Notis: OpenPose-preprocessor laddar ofta ner annotator-modeller första gången (från HuggingFace). Om du kör offline behöver de laddas ner manuellt.
