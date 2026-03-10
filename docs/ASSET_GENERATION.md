# Asset Generation (How-To)

Denna guide visar hur du tar fram, granskar och kuraterar grafik, ljud och animationer för Siffersafari.

Regeln i repo:t är enkel: endast godkända produktionsassets ska ligga i `assets/`. Tillfälliga exporter, utkast och testmaterial ska ligga i `artifacts/` tills de antingen används eller kastas.

---

## Quick Start

```bash
# 1. Generera eller bearbeta ett ljud
dart run scripts/generate_sfx_wav.dart --prompt "bell chime" --output artifacts/bell.wav

# 2. Konvertera till MP3 för appen
powershell -ExecutionPolicy Bypass -File scripts/convert_wav_to_mp3.ps1 -InputFile artifacts/bell.wav -OutputFile assets/sounds/bell.mp3 -Bitrate 192

# 3. Generera Android-ikoner
dart run scripts/generate_android_launcher_icons.dart --input assets/images/app_logo.png --output android/app/src/main/res/
```

---

## 1. Graphics & Animation Assets

Grafik till appen tas fram utanför runtime-koden och läggs sedan in manuellt i `assets/` efter granskning.

Vanliga mål:
- tema-bakgrunder
- quest-illustrationer
- karaktärsbilder och riggade karaktärsanimationer (Rive)
- UI-effekter (Lottie)

### Rekommenderat arbetsflöde

1. Ta fram ett eller flera utkast utanför appen.
2. Lägg utkasten i `artifacts/` under en beskrivande mapp.
3. Granska stil, transparens, dimensioner och läsbarhet.
4. Flytta bara godkända filer till rätt plats i `assets/`.
5. Verifiera i appen innan commit.

### Ville i UI

För Ville gäller just nu:
- använd Rive (`assets/characters/ville/rive/ville_character.riv`) för karaktärsrörelser och state machine
- använd Lottie i `assets/ui/lottie/` för UI-effekter (confetti/stars/success/error)
- om Rive-fil eller state machine saknas ska UI:t falla tillbaka till placeholder/fallback

Se `docs/CHARACTER_ANIMATIONS.md` för hur den delen är tänkt att användas i UI:t.

### Organize Approved Assets

```bash
# Exempel: bakgrund
cp artifacts/jungle/background_v3.png assets/images/themes/jungle/background.png

# Exempel: Rive-karaktär
cp artifacts/ville/ville_character.riv assets/characters/ville/rive/ville_character.riv

# Exempel: UI-Lottie-effekt
cp artifacts/ui/confetti.json assets/ui/lottie/confetti.json

# Verifiera att assets finns med i pubspec
grep -r "assets/images" pubspec.yaml
grep -r "assets/characters" pubspec.yaml
grep -r "assets/ui/lottie" pubspec.yaml
grep -r "assets/sounds" pubspec.yaml
```

---

## 2. Sound Effects (gen_sfx_wav.dart)

Generera eller bearbeta ljudeffekter:

```bash
# Generera ett ljud (ex: bell chime)
dart run scripts/generate_sfx_wav.dart \
  --prompt "bell chime, bright, cheerful" \
  --duration 1 \
  --output artifacts/bell.wav

# Konvertera WAV till MP3 (sparar ~90% storlek)
powershell -ExecutionPolicy Bypass -File scripts/convert_wav_to_mp3.ps1 `
  -InputFile artifacts/bell.wav `
  -OutputFile assets/sounds/bell.mp3 `
  -Bitrate 192
```

**Sound-format:**
- **WAV:** RAW audio, stor fil (~100 KB för 1 sek)
- **MP3:** Komprimerad, liten fil (~10 KB för 1 sek, 128-192 kbps)
- **Target:** MP3 för alla produktionsfiler

**Befintliga ljud:**
- `assets/sounds/background_music.wav` — Loop music
- `assets/sounds/celebration.wav` — Achievement unlocked
- `assets/sounds/correct.wav` — Rätt svar
- `assets/sounds/wrong.wav` — Fel svar
- `assets/sounds/click.wav` — Button tap

Se [CONVERT_TO_MP3.md](../assets/sounds/CONVERT_TO_MP3.md) för konvertering av alla WAV.

---

## 3. Icons (Android Launcher)

Generera launcher-ikoner för Android:

```bash
# Generera ikoner från en base-image (1024x1024 PNG)
dart run scripts/generate_android_launcher_icons.dart \
  --input assets/images/app_logo.png \
  --output android/app/src/main/res/

# Verifiera att alla storlekar genererades
ls android/app/src/main/res/mipmap-*/
```

**Output:**
```
android/app/src/main/res/
  mipmap-ldpi/
    ic_launcher.png (36x36)
  mipmap-mdpi/
    ic_launcher.png (48x48)
  mipmap-hdpi/
    ic_launcher.png (72x72)
  mipmap-xhdpi/
    ic_launcher.png (96x96)
  ... (och fler)
```

---

## 4. Pre-flight Checks

Innan du committar nya assets:

```bash
# 1. Verifiera pubspec.yaml listar alla assets
grep -r "assets/images" pubspec.yaml
grep -r "assets/characters" pubspec.yaml
grep -r "assets/ui/lottie" pubspec.yaml
grep -r "assets/sounds" pubspec.yaml

# 2. Checkra filstorlek (goal: < 50 MB APK)
du -sh assets/

# 3. Verifiera inga WAV-filer ligger i assets/sounds/
ls -la assets/sounds/*.wav  # Ska vara tomt!

# 4. Analyser ljud-kvalitet
# Lyssna på ett audio-sample:
# - Klart ljud? Inget klipp/distortion?
# - Rätt längd?

# 5. Analys bild-kvalitet
# Öppna PNG i bild-viewer:
# - Rätt transparens?
# - Rätt dimensioner?
# - Ingen artifakter?

# 6. Kör tester
flutter test
```

---

## 5. Workflow Tips

### Iteration Workflow (Draft → Final)

```
1. DRAFT
  └─ Ta fram flera utkast utanför appen
  └─ Spara till artifacts/
  └─ Välj 2–3 bästa

2. REVIEW
   └─ Öppna bilder i bild-viewer
   └─ Döm på stil, transparens, detaljer
   └─ Markera "godkänd" eller "behöver revision"

3. FINAL
   └─ Kopiera godkänd bild till assets/
   └─ Uppdatera pubspec.yaml om ny kategori
   └─ Testa i appen (flutter run)

4. COMMIT
   └─ Bara slutlig bild commitas till Git (artifacts/ är .gitignored)
   └─ Commit message: "assets: add new jungle background"
```

### Curation Checklist

- rätt storlek för målplattformen
- rena kanter och korrekt transparens
- konsekvent stil mot resten av appen
- begripligt motiv även på mindre mobilytor
- rimlig filstorlek

---

## Resources

- **Karaktärsanimation:** [CHARACTER_ANIMATIONS.md](CHARACTER_ANIMATIONS.md)
- **Sound conversion:** [assets/sounds/CONVERT_TO_MP3.md](../assets/sounds/CONVERT_TO_MP3.md)
