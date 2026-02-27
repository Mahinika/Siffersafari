# Snabbstart Guide

## Uppdatering

- 2026-02-26: Aktuell implementationsstatus finns i `README.md` under sektionen **Status (2026-02-26)** och i `IMPLEMENTATION_STATUS.md`.

## Förutsättningar

För att kunna köra och utveckla detta projekt behöver du:

1. **Flutter SDK** (version 3.0+)
   - Installera från: https://flutter.dev/docs/get-started/install
   - Verifiera: `flutter doctor`

2. **Dart SDK** (inkluderat i Flutter)

3. **IDE med Flutter-stöd**
   - Visual Studio Code med Flutter extension
   - Android Studio med Flutter plugin
   - IntelliJ IDEA med Flutter plugin

4. **Git** (för versionskontroll)

5. **Android Studio** eller **Xcode** (för att köra på emulator/simulator)

## Installation & Setup

### Steg 1: Klona eller navigera till projektet

```bash
cd d:\Projects\Personal\Multiplikation
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

## Utvecklingskommandon

### Kör appen

```bash
# Debug mode med hot reload
flutter run

# Release mode (optimerad)
flutter run --release

# På specifik plattform
flutter run -d chrome     # Webb
flutter run -d windows    # Windows
```

### Testning

```bash
# Kör alla tester
flutter test

# Kör specifikt test
flutter test test/question_generator_test.dart

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

# iOS (kräver Xcode och Mac)
flutter build ios --release

# Webb
flutter build web --release
```

## Projektstruktur - Snabböversikt

```
lib/
├── main.dart                  # Entry point
├── core/                      # Kärnfunktionalitet
│   ├── config/               # Konfiguration
│   ├── constants/            # Konstanter
│   ├── di/                   # Dependency Injection
│   └── services/             # Business logic services
├── data/                      # Data layer
│   └── repositories/         # Data repositories
├── domain/                    # Domain layer
│   ├── entities/             # Business entities
│   └── enums/                # Enumerations
└── presentation/              # UI layer
    ├── screens/              # Full screens
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
   - `TODO.md` - Vad som behöver göras härnäst

3. **Börja implementera:**
   - Välj en uppgift från `TODO.md`
   - Skapa en ny branch: `git checkout -b feature/my-feature`
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
- `TODO.md` - Kända issues och framtida features
- `/memories/session/plan.md` - Fullständig projektplan

---

**Lycka till med utvecklingen! 🚀**
