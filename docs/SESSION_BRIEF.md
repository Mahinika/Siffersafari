# Session brief (Multiplikation)

> Syfte: hålla en kort, stabil status så vi inte behöver bära allt i chat-kontexten.
> Håll detta dokument kort (helst < 30–40 rader). Uppdateras löpande av Copilot.

## Mål just nu
- Stabilisera arbetsflöde när chat-kontext blir lång (extern kontext + repo-sök).
- (Aktuellt spår) Ta fram en **konsekvent run-loop** för `character_v2` (minimera drift). Preview kan vara **4 frames @ 256px (2×2 spritesheet)**; appen vill i slutändan ha **1 PNG per frame**.

## Status nu
- App: **Siffersafari** (mattespel 6–12), Android-only, offline-first, flera profiler.
- ROI_MEDIUM (DX): opt-in exempelprofiler via `SEED_EXAMPLE_PROFILES` + Settings “Radera all data” wipe.
- Svårighetsförslag (steg): **pågående quiz-svar räknas direkt** (sparas som “incomplete” historik) så underlaget uppdateras även om barnet avbryter. Nollställs automatiskt när barnet startar samma räknesätt igen.
- Under/I linje/Över-indikatorn i Föräldraläge bygger (när det finns underlag) på **förslaget (steg)** utifrån barnets svar, inte bara på inställt steg.
- QA-rutin: `flutter analyze` → minsta relevanta `flutter test`-subset (full suite vid stora ändringar).
- Säkerhet/tests: enhetstester för PIN/lockout/recovery i `test/parent_pin_service_test.dart`; regression täcker backup-kod-unikhet + case-insensitiv inmatning.
- Quiz/progression: edge-case tests för in-progress underlag + purge i `test/quiz_progression_edge_cases_test.dart`.
- Integration: kritiska parent-flöden (PIN, recovery, profil) täcks i `integration_test/parent_features_test.dart`.
- Smoke tests: 5 automatiserade tests i `integration_test/app_smoke_test.dart` (app-start, settings, achievements, profile switcher, full quiz flow).
- Pixel_6: deterministiska flöden via `scripts/flutter_pixel6.ps1` (sync/install/run).
- ComfyUI: servern svarar på `http://127.0.0.1:8000/system_stats`.
- Animation: pipeline finns för frame-för-frame PNG → GIF/strip/audit (utan emulator).
- Generator: `scripts/generate_character_v2_animation_frames.ps1` stödjer `-StableSeed`, `-ChainInit`, `-AlphaAll` (skriver till `artifacts/comfyui/anim_<anim>_<timestamp>/`).
- GIF-preview (utan emulator): `scripts/preview_animation_gif.dart` + `scripts/inspect_animation_gif.dart`.
- Widget: `lib/presentation/widgets/mascot_view.dart` kan animera genom att cykla en `frames`-lista (asset-paths).
- Ny Ville (preview): `assets/images/themes/jungle/character_v2_preview.png` + `..._alpha.png` används för att prova i appen utan att skriva över canonical `character_v2.png`.
- Spritesheet (8 frames → spritesheet i ComfyUI): öppna `scripts/comfyui/workflows/character_sprite_sheet_8frames_ui.json` (UI-layout) eller kör `scripts/comfyui/workflows/character_sprite_sheet_8frames_api.json` via `scripts/generate_images_comfyui.dart`.
- Spritesheet (4 frames @ 256px, 2x2): öppna `scripts/comfyui/workflows/character_sprite_sheet_4frames_256_ui.json` eller kör `scripts/comfyui/workflows/character_sprite_sheet_4frames_256_api.json`.
- Stabilitet: WAS-noden `Mask Fill Holes` kan krascha på batch-masker; API-workflows bypassar den och använder `ThresholdMask` direkt som alpha.
- Audit: `scripts/audit_animation_frames.dart` flaggar translation-risk och exakta duplikatframes.

## Nästa steg (konkret)
- Verifiera manuellt: starta ett quiz, svara 3–5 frågor, gå till Föräldraläge och se att “Underlag … frågor” uppdaterats utan att behöva avsluta quizet.
- (När vi återupptar) Kör `scripts/generate_character_v2_animation_frames.ps1 -Anim run -Frames 8 -StableSeed` (ev. `-ChainInit`) och gör GIF-preview med `scripts/preview_animation_gif.dart`.
- För “spring” utan drift: håll `denoise` låg och styr pose separat (t.ex. OpenPose/ControlNet) + lås identitet med stark bildreferens (init/IP-Adapter).

## Nyckeldocs (när vi tappar tråden)
- `README.md` (status + QA)
- `docs/ARCHITECTURE.md`, `docs/SERVICES_API.md`
- `docs/COMFYUI_STRATEGI.md`

## Hårda constraints ("sant även om vi glömmer chatten")
- Plattform: Android-first / offline-first
- Målgrupp: 6–12
- Default-device för körning/QA: Pixel_6 (när relevant)

## Senast verifierat
- `flutter analyze`: OK (2026-03-04, exit 0)
- Tester: full suite (`flutter test`) kört och grönt (2026-03-04)
- Tester (subset): `flutter test test/app_widget_flows_test.dart` kört och grönt (2026-03-04)
- Enhet/emulator: Pixel_6 (script-baserat flöde), samt emulator-5554 har använts tidigare

## Snabb felsöknings-snapshot (bara om relevant)
- Idle (AI): utan chaining kan frames bli identiska (exakta duplikat) om prompt/denoise är för “snäll”.
- Motmedel: använd `-StableSeed` (samma seed över alla frames) och ev. `-ChainInit` för mer sammanhängande loop (men håll koll på artefakt-ackumulering).
- Pose/rörelse: att höja `denoise` för att få “spring” ger snabbt identitets-drift (hatt/kläder/färger). För tydlig rörelse utan drift → håll `denoise` låg och styr pose separat (t.ex. OpenPose/ControlNet) + lås identitet med stark bildreferens (init/IP-Adapter).
