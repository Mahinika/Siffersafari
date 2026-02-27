# Projektdokumentation

## Översikt

Detta är ett pedagogiskt mattespel för barn (6-13+ år) som bygger på vetenskaplig forskning om effektiv inlärning av matematik.

## Projektstruktur

```
lib/
├── core/                       # Kärnfunktionalitet
│   ├── config/                # Konfigurationsfiler
│   │   └── difficulty_config.dart
│   ├── constants/             # Konstanter
│   │   └── app_constants.dart
│   ├── di/                    # Dependency Injection
│   │   └── injection.dart
│   └── services/              # Services
│       ├── question_generator_service.dart
│       ├── audio_service.dart
│       ├── adaptive_difficulty_service.dart (TODO)
│       └── spaced_repetition_service.dart (TODO)
│
├── data/                      # Dataskikt
│   └── repositories/          # Repositories
│       └── local_storage_repository.dart
│
├── domain/                    # Domänlogik
│   ├── entities/             # Entiteter
│   │   ├── question.dart
│   │   ├── user_progress.dart
│   │   └── quiz_session.dart
│   └── enums/                # Enums
│       ├── age_group.dart
│       ├── operation_type.dart
│       ├── difficulty_level.dart
│       ├── app_theme.dart
│       └── mastery_level.dart
│
└── presentation/              # Presentation/UI
    ├── screens/              # Skärmar
    │   ├── home_screen.dart
    │   ├── quiz_screen.dart (TODO)
    │   ├── results_screen.dart (TODO)
    │   └── parent_dashboard_screen.dart (TODO)
    └── widgets/              # Återanvändbara widgets
        └── (TODO)
```

## Nästa Steg

### Fas 2: Kärn-Lärsystem (Vecka 3-4)

#### 1. Adaptivt Svårighetssystem
- **Fil:** `lib/core/services/adaptive_difficulty_service.dart`
- **Funktionalitet:**
  - Spåra användarens prestanda över senaste 5-10 frågorna
  - Justera svårighetsgrad baserat på framgångsfrekvens
  - Målet: 70-80% framgångsfrekvens
  - Om >85% korrekt → öka svårighetsgrad
  - Om <60% korrekt → minska svårighetsgrad

#### 2. Spaced Repetition System
- **Fil:** `lib/core/services/spaced_repetition_service.dart`
- **Funktionalitet:**
  - Algoritm för att schemalägga repetition av tidigare frågor
  - Intervaller: 2-3 dagar → 1 vecka → 2 veckor
  - Prioritera frågor med tidigare felaktiga svar
  - Balansera nya koncept (70%) med repetition (30%)

#### 3. Feedback-system
- **Fil:** `lib/core/services/feedback_service.dart`
- **Funktionalitet:**
  - Generera specifik, konstruktiv feedback för varje fråga
  - Förklara konceptet bakom rätt/fel svar
  - Olika feedback-nivåer baserat på åldersgrupp

#### 4. Quiz-skärm
- **Fil:** `lib/presentation/screens/quiz_screen.dart`
- **Funktionalitet:**
  - Visa fråga med tydlig formatering
  - Inmatningsalternativ (multiple choice eller numerisk)
  - Timer (valfri)
  - Framstegsindikator
  - Omedelbar feedback-modal

#### 5. Resultatskärm
- **Fil:** `lib/presentation/screens/results_screen.dart`
- **Funktionalitet:**
  - Visa sammanfattning (korrekta svar, tid, poäng)
  - Visuell representation (stjärnor, medaljer)
  - Upplåsningar och achievements

## Kod-generering

Efter att ha implementerat Hive-adapters, kör:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Detta kommer att generera:
- `user_progress.g.dart` - Hive TypeAdapter för UserProgress

## Testning

För att köra tester:

```bash
# Alla tester
flutter test

# Med coverage
flutter test --coverage

# Specifikt test
flutter test test/question_generator_test.dart
```

## Dependencies

Viktiga dependencies och deras syfte:

- **flutter_riverpod** - State management
- **hive** - Lokal databas (NoSQL)
- **audioplayers** - Ljud och musik
- **flutter_animate** - Animationer
- **lottie** - Vektorbaserade animationer
- **google_fonts** - Typografi
- **get_it** - Dependency injection
- **equatable** - Enkel jämförelse av objekt
- **uuid** - Generera unika ID:n

## Konventioner

### Kodstil
- Använd `const` konstruktorer där möjligt
- Trailing commas för multiline arguments
- Single quotes för strings
- Uttryckliga return types

### Filnamning
- Snake case: `my_file.dart`
- Screens: `*_screen.dart`
- Widgets: `*_widget.dart`
- Services: `*_service.dart`

### Git Commits (Rekommendation)
- `feat:` - Ny funktionalitet
- `fix:` - Buggfix
- `refactor:` - Kod-refaktorering
- `test:` - Testning
- `docs:` - Dokumentation
- `style:` - Formatering

## Pedagogisk Grund

Detta projekt baseras på vetenskaplig forskning:

1. **Spaced Repetition** - Beprövad metod för långtidsminne
2. **Retrieval Practice** - Testning förstärker inlärning
3. **Interleaving** - Blanda olika problemtyper
4. **Immediate Feedback** - Omedelbar, specifik återkoppling
5. **Growth Mindset** - Betona ansträngning över resultat
6. **Adaptive Learning** - Anpassa svårighetsgrad till individen

Se `/memories/session/plan.md` för fullständig forskningssammanfattning.
