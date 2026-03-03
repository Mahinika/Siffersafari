# Beslut & antaganden (Multiplikation)

> Syfte: hålla stabila beslut/antaganden utanför chatten så vi kan återuppta arbetet utan att du behöver repetera.
> Princip: kortfattat, datumstämplat, max 1–3 rader per punkt.

## 2026-03-03
- Vi hanterar långt kontextbehov via "extern kontext": uppdatera `docs/SESSION_BRIEF.md` och denna logg, och hämta detaljer via repo-sök istället för chat-historik.
- Standard QA-flöde: `flutter analyze` → minsta relevanta `flutter test`-subset (full suite bara vid stora ändringar).
- När device-target behövs: defaulta till Pixel_6 om inget annat sägs.
- Appnamn: **Siffersafari**.
- Android-only + offline-first + flera profiler (målgrupp 6–12).
- Install/run ska vara deterministiskt när det behövs: använd `scripts/flutter_pixel6.ps1` (särskilt `-Action sync`).
- UI-screenshot-regression: föredra Flutter-side screenshots via `integration_test/screenshots_test.dart` och extrahera PNG med `scripts/extract_integration_screenshots.ps1` till `artifacts/`.
- ComfyUI baseUrl för våra scripts: `http://127.0.0.1:8000`.
