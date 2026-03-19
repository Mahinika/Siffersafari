# Contributing (Siffersafari)

Tack för att du vill bidra.

## Snabb QA-rutin (före commit/push)

Kör detta som standard innan du committar eller pushar:

```bash
# 1) Statisk analys
flutter analyze

# 2) Tester: kor minsta relevanta subset for andringen
flutter test test/unit/logic/adaptive_difficulty_test.dart

# 3) Vid stora commits, merges eller bred paverkan:
flutter test
```

## VS Code-tasks (rekommenderat)

Det finns fardiga tasks i `.vscode/tasks.json` sa du kan kora QA med ett klick:

- "QA: Analyze + Test (valfri path)" (standard)
- "QA: Analyze + Full Test (stora andringar)"
- "Pixel_6: Sync + QA (valfri testpath)" (sakrast nar du vill vara 100% saker att emulatorn kor senaste APK)

## VS Code debug-flode

Det finns fardiga launch-konfigurationer i `.vscode/launch.json`:

- "Flutter: Debug"
- "Flutter: Debug (Pixel_6)"
- "Flutter: Profile (Pixel_6)"
- "Flutter: Release (Pixel_6)"

Det gor att du ofta kan kora appen direkt fran `Run and Debug` i stallet for att skriva `flutter run` manuellt.

## Rekommenderade extensions

Workspace rekommenderar dessa tillagg i `.vscode/extensions.json`:

- Dart
- Flutter
- Error Lens
- Mermaid-stod for dokumentation

## Android (rekommenderat): Pixel_6-script for deterministisk install

Om emulatorn ibland verkar kora en gammal APK, anvand PowerShell-scriptet som alltid riktar in sig pa `Pixel_6` och gor ett deterministiskt build+install-flode:

```bash
# SYNC: bygg + installera exakt APK + starta om appen
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync

# RUN: dev-lage med hot reload
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action run

# INSTALL: bara bygg + installera
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action install
```

## Branch/PR (enkel rutin)

- Gor andringen liten och tydlig.
- Lagg till eller uppdatera test om beteendet andras.
- Skriv en commit message som beskriver vad och varfor.
