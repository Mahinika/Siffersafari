# Snabbstart Guide

> Obs: Den här filen är en **kort pekare** för att undvika att duplicera innehåll från `README.md`.
> För aktuell status, QA-rutin och rekommenderade kommandon: se `README.md`.

## Uppdatering

- 2026-03-01: Aktuell implementationsstatus finns i `README.md` under sektionen **Status (2026-03-01)** och i `SESSION_BRIEF.md`.
- Rekommenderad QA-rutin (före commit/push) finns även sammanfattad i `CONTRIBUTING.md`.

## TL;DR (minsta som krävs)

```bash
flutter pub get
flutter analyze
flutter test test/widget/app_home_test.dart
```

För deterministisk körning på Pixel_6:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync
```

## Förutsättningar

För att kunna köra och utveckla detta projekt behöver du:

1. **Flutter SDK** (version 3.10+ / Dart 3)
   - Installera från: https://flutter.dev/docs/get-started/install
   - Verifiera: `flutter doctor`

2. **Dart SDK** (inkluderat i Flutter)

3. **IDE med Flutter-stöd**
   - Visual Studio Code med Flutter extension
   - Android Studio med Flutter plugin
   - IntelliJ IDEA med Flutter plugin

4. **Git** (för versionskontroll)

5. **Android Studio** (för Android SDK + emulator)

> Not: Detta projekt är **Android-only**. iOS/web/desktop ingår inte i mål-scope.

## Installation & Setup

### Steg 1: Klona eller navigera till projektet

```bash
cd <repo-root>  # t.ex. d:\Projects\Personal\Siffersafari
```

### Steg 2: Installera dependencies

```bash
flutter pub get
```

Detta installerar alla paket som definieras i `pubspec.yaml`.

### Steg 3: Generera kod (Hive TypeAdapters)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Detta genererar nödvändiga filer:
- `lib/domain/entities/user_progress.g.dart`

### Steg 4: Lägg till assets (temporärt kan du skippa detta)

För en fullständig upplevelse, lägg till:
- Ljudfiler i `assets/sounds/` (se `assets/sounds/README.md`)
- Animationer i `assets/animations/` (se `assets/animations/README.md`)
- Bilder i `assets/images/` (se `assets/images/README.md`)

**Alternativ:** Appen kommer att köra utan assets, men ljud och animationer kommer inte att fungera.

### Steg 5: Kör appen

```bash
# Lista tillgängliga enheter
flutter devices

# Kör på specifik enhet
flutter run -d <device-id>

# Eller bara
flutter run
```

Detta startar appen i debug-läge med hot reload.

### Rekommenderat på Android: Pixel_6-script (för att undvika "fel APK")

Det finns ett deterministiskt PowerShell-script som alltid riktar in sig på emulatorn **Pixel_6**, väntar tills Android är redo, och kan bygga/installerar på ett sätt som minskar risken att en gammal APK råkar ligga kvar.

```bash
# SYNC: bygg + installera + starta om + starta appen (säkrast när du vill att emulatorn matchar koden)
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync

# RUN: utvecklingsläge med hot reload
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action run

# INSTALL: bara bygg + installera (startar inte appen)
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action install
```

## Utvecklingskommandon

### Kör appen

```bash
# Debug mode med hot reload
flutter run

# Release mode (optimerad)
flutter run --release
```

### Testning

#### Rekommenderad QA-rutin (före commit/push)

```bash
# 1) Statisk analys
flutter analyze

# 2) Tester: kör minsta relevanta subset för ändringen
# Exempel:
flutter test test/unit/logic/adaptive_difficulty_test.dart

# 3) Vid "stora" commits/merges (många filer, refactor, bred påverkan):
flutter test
```

```bash
# Kör alla tester
flutter test

# Kör specifikt test
flutter test test/unit/logic/adaptive_difficulty_test.dart

# Med coverage report
flutter test --coverage

# Visa coverage i HTML
genhtml coverage/lcov.info -o coverage/html
```

### Kodanalys

```bash
# Analysera kod för potentiella problem
flutter analyze

# Format kod automatiskt
dart format lib/ test/

# Fixa enkla linting-issues
dart fix --apply
```

### Bygga för produktion

```bash
# Android APK
flutter build apk --release

# Android App Bundle (för Play Store)
flutter build appbundle --release
```

## Projektstruktur - Snabböversikt

```
lib/
├── main.dart                  # Entry point
├── core/                      # Kärnfunktionalitet
│   ├── config/               # Konfiguration
│   ├── constants/            # Konstanter
│   ├── di/                   # Dependency Injection
│   ├── utils/                # Små utilities (t.ex. navigation/transitions)
│   └── services/             # Business logic services
├── data/                      # Data layer
│   └── repositories/         # Data repositories
├── domain/                    # Domain layer
│   ├── entities/             # Business entities
│   └── enums/                # Enumerations
│   └── services/              # Domain services (t.ex. ParentPinService)
└── presentation/              # UI layer
    ├── screens/              # Full screens
   │   ├── app_entry_screen.dart
   │   ├── profile_picker_screen.dart
    └── widgets/              # Reusable widgets
```

## Vanliga Problem & Lösningar

### Problem: "Flutter command not found"
**Lösning:** Installera Flutter SDK och lägg till i PATH.
```bash
# Verifiera installation
flutter doctor
```

### Problem: "Hive type adapter not found"
**Lösning:** Kör code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problem: "Asset not found"
**Lösning:** Lägg till placeholder-filer eller kommentera ut asset-användning temporärt.

### Problem: Gradle build errors (Android)
**Lösning:** 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Problem: Pod install errors (iOS)
**Lösning:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

## Tips för Effektiv Utveckling

1. **Använd Hot Reload** - Tryck `r` i terminalen efter ändringar
2. **Använd Hot Restart** - Tryck `R` för att starta om appen
3. **Aktivera DevTools** - Tryck `v` för att öppna Flutter DevTools
4. **Använd Widget Inspector** - Visualisera widget-trädet
5. **Aktivera Performance Overlay** - Tryck `p` för att se FPS

## Nästa Steg

1. **Bekanta dig med koden:**
   - Kolla på `lib/main.dart` - entry point
   - Utforska `lib/domain/entities/` - datamodeller
   - Kolla på `lib/core/services/question_generator_service.dart` - fråggenerering

2. **Läs dokumentationen:**
   - `docs/ARCHITECTURE.md` - Projektstruktur och design
   - `docs/SESSION_BRIEF.md` - Status och nästa steg

3. **Börja implementera:**
   - Se [ADD_FEATURE.md](ADD_FEATURE.md) för steg-för-steg guiden
   - (Valfritt) Skapa en ny branch: `git checkout -b feature/my-feature`
   - Implementera och testa
   - Commit: `git commit -m "feat: add my feature"`

## Resurser

- **Flutter Dokumentation:** https://flutter.dev/docs
- **Dart Dokumentation:** https://dart.dev/guides
- **Riverpod Dokumentation:** https://riverpod.dev
- **Hive Dokumentation:** https://docs.hivedb.dev

## Support

För frågor eller problem, se:
- `docs/ARCHITECTURE.md` - Teknisk dokumentation
- `docs/ADD_FEATURE.md` - Guide för att lägga till features
- `docs/SESSION_BRIEF.md` - Kort status + nästa steg

---

**Lycka till med utvecklingen!**
