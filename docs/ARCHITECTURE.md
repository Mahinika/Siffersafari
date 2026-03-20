# Arkitektur (As-Is)

Detta dokument beskriver aktuell implementation i repo:t (uppdaterad 2026-03-18).

## Snabboversikt

- Plattform: Flutter (Android-first)
- Arkitektur: hybrid (`app`, `features`, kvarvarande `presentation`, `core`, `domain`, `data`)
- State: Riverpod (`StateNotifierProvider` + `Provider`)
- DI: GetIt
- Persistens: Hive (`user_progress`, `settings`, `quiz_history`)
- Animation:
  - SVG-first for mascot-runtime i produkt-UI
  - Flutter-styrda reaktioner ovanpa composite-SVG i `MascotCharacter`
  - Lottie for godkanda UI-effekter
  - optional `.riv`-filer och blueprint-material finns kvar som framtida enhancement-spor, men ar inte en aktiv runtime-dependency i appens huvudfloden

## Startup och bootstrap

1. `main()` i `lib/main.dart`
2. Global felhantering (Flutter/Platform/Isolate)
3. `initializeDependencies(initializeHive: false)` for tidig DI-registrering
4. `_initializeAsync()`:
   - `Hive.initFlutter()`
   - `initializeDependencies(openQuizHistoryBox: false)`
   - `quiz_history` oppnas i bakgrunden
5. `ProviderScope` + `MathGameApp`
6. `StartupSplashGate` -> `StartupRouterScreen`

## Lager och ansvar

### app/ + features/ + presentation/

UI-lagret ar nu hybrid under overgangen till feature-first struktur:
- `lib/app/bootstrap/` for startup och routing in i appen
- `lib/features/` for featureagda skarmar, dialoger och widgets
- `lib/presentation/` for kvarvarande legacy-UI som inte flyttats an

Viktiga skarmar:
- `app/bootstrap/presentation/startup_router_screen.dart`
- `onboarding_screen.dart`
- `features/profiles/presentation/screens/profile_selection_screen.dart`
- `home_screen.dart`
- `quiz_screen.dart`
- `results_screen.dart`
- `story_map_screen.dart`
- `parent_pin_screen.dart`
- `pin_recovery_screen.dart`
- `parent_dashboard_screen.dart`

### core/

Teknisk app-logik, providers, tema och utilities.

Viktiga delar:
- `core/di/injection.dart`
- `core/providers/quiz_provider.dart`
- `core/providers/user_provider.dart`
- `core/services/question_generator_service.dart`
- `core/services/app_update_service.dart`
- `core/services/quest_progression_service.dart`
- `core/services/story_progression_service.dart`

### domain/

Flutter-fri domanlogik: entiteter, enums och rena tjanster.

Viktiga tjanster:
- `AdaptiveDifficultyService`
- `FeedbackService`
- `ParentPinService`
- `SpacedRepetitionService`
- `DataExportService`

### data/

Repository-implementation for lokal lagring:
- `LocalStorageRepository` (Hive access + typed helpers)

## Huvudfloden i produkten

1. Barn valjer/skapar profil
2. Home visar rekommenderad progression + storystatus
3. Quiz startas via `QuizNotifier.startSession(...)`
4. Svar hanteras i `QuizNotifier.submitAnswer(...)`
   - ljudfeedback
   - poang/streak
- adaptiv difficulty step per raknesatt
- spaced repetition-review per fraga nar funktionen ar aktiverad
- in-progress persistens
5. Resultat visas i `ResultsScreen`
6. `UserNotifier.applyQuizResult(...)` uppdaterar:
   - user stats
   - mastery
   - achievements
   - quest/story progression
   - permanent quizhistorik

## Parent mode (sakerhet och styrning)

- PIN verifiering via BCrypt-hash i `ParentPinService`
- lockout efter 5 felaktiga forsok (5 minuter)
- security question-baserad recovery
- dashboard med statistik och export
- app update-check via GitHub Releases API + OTA-installation pa Android

## Persistensmodell

Hive-boxar:
- `user_progress`: `UserProgress` profiler
- `settings`: aktiv profil, onboardingstatus, parent settings, quest state, PIN data
- `quiz_history`: sessioner (in-progress + complete)

Designval:
- in-progress session sparas med deterministisk nyckel per `userId + operation`
- legacy in-progress entries rensas for att undvika dubbelrakning
- quizhistory valideras defensivt innan den anvands

## Test och kvalitet

Aktiva testlager:
- unit: logik, services, audits
- widget: huvudfloden i UI
- integration: smoke, parent features, PIN recovery, screenshots

CI/workflows:
- `.github/workflows/flutter.yml`: analyze + test
- `.github/workflows/build.yml`: release build + signering + GitHub Release
- `.github/workflows/release-guard.yml`: snabb releasevalidering + APK size guard

## Kanda tekniska noteringar

- Vissa dokument i repo:t innehaller historiska stegplaner. Denna fil beskriver endast nulaget.
- Vissa terminalmiljoer visar svenska tecken felaktigt (mojibake). Filinnehall i repo:t ar uppdaterat i UTF-8.
- `assets/characters/mascot/rive/mascot_character.riv` ar fortfarande placeholder/demo-material och inte del av nuvarande produkt-runtime.
- Om Rive aterintroduceras i produkt-UI senare ska det goras som ett explicit nytt integrationssteg, inte som dold fallback.

## Relaterade dokument

- `docs/PROJECT_STRUCTURE.md`
- `docs/SERVICES_API.md`
- `docs/DECISIONS_LOG.md`
- `docs/SESSION_BRIEF.md`
