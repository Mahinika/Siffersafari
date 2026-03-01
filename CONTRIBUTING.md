# Contributing (Siffersafari)

Tack för att du vill bidra!

## Snabb QA-rutin (före commit/push)

Kör detta som standard innan du committar/pushar:

```bash
# 1) Statisk analys
flutter analyze

# 2) Tester: kör minsta relevanta subset för ändringen
# Exempel:
flutter test test/question_generator_test.dart

# 3) Vid "stora" commits/merges (många filer, refactor, bred påverkan):
flutter test
```

## Android (rekommenderat): Pixel_6-script för deterministisk install

Om emulatorn ibland verkar köra en gammal APK, använd PowerShell-scriptet som alltid riktar in sig på **Pixel_6** och gör ett deterministiskt build+install-flöde:

```bash
# SYNC: bygg + installera exakt APK + starta om appen (säkrast när emulatorn måste matcha koden)
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync

# RUN: dev-läge med hot reload
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action run

# INSTALL: bara bygg + installera (startar inte appen)
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action install
```

## Branch/PR (enkel rutin)

- Gör ändringen liten och tydlig.
- Lägg till/uppdatera test om beteendet ändras.
- Skriv en commit message som beskriver vad och varför.
