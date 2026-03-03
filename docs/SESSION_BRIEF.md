# Session brief (Multiplikation)

> Syfte: hålla en kort, stabil status så vi inte behöver bära allt i chat-kontexten.
> Håll detta dokument kort (helst < 30–40 rader). Uppdateras löpande av Copilot.

## Mål just nu
- Stabilisera arbetsflöde när chat-kontext blir lång (extern kontext + repo-sök).
- (Aktuellt spår) Få ComfyUI batch-generering (`--count >1`) att fungera stabilt.

## Status nu
- App: **Siffersafari** (mattespel 6–12), Android-only, offline-first, flera profiler.
- Arkitektur: Clean-ish (`lib/domain` Flutter-fritt, `lib/core` tekniskt, `lib/presentation` UI), state via Riverpod, persistens via Hive.
- QA-rutin: `flutter analyze` → minsta relevanta `flutter test`-subset (full suite vid stora ändringar).
- Pixel_6: deterministiska flöden via `scripts/flutter_pixel6.ps1` (sync/install/run).
- ComfyUI: servern svarar på `http://127.0.0.1:8000/system_stats`.
- ComfyUI: enstaka generering (`--count 1`) lyckas; batch (`--count 12`) gav exit code 1 (fånga logg nästa gång).

## Nästa steg (konkret)
- Vid nästa ComfyUI-batch-fel: fånga stderr/stdout och spara rålogg under `artifacts/comfyui/` och sammanfatta felet här.
- Om felet är intermittent: testa `--count 2` för att snäva in.

## Nyckeldocs (när vi tappar tråden)
- `README.md` (status + QA)
- `docs/ARCHITECTURE.md`, `docs/SERVICES_API.md`
- `docs/COMFYUI_STRATEGI.md`

## Hårda constraints ("sant även om vi glömmer chatten")
- Plattform: Android-first / offline-first
- Målgrupp: 6–12
- Default-device för körning/QA: Pixel_6 (när relevant)

## Senast verifierat
- `flutter analyze`: OK (senast kört, exit 0)
- Tester: senast grönt enligt README (2026-03-01); ej kört i detta spår
- Enhet/emulator: Pixel_6 (script-baserat flöde), samt emulator-5554 har använts tidigare

## Snabb felsöknings-snapshot (bara om relevant)
- Symptom: `dart run scripts/generate_images_comfyui.dart ... --count 12` avslutar med exit code 1.
- Senaste bra kommando: samma kommando med `--count 1` (OK).
- Senaste fel/exit code: batch `--count 12` (exit 1).
- Hypotes: timeout/polling/partial outputs i ComfyUI history eller filskrivning vid multi-run.
