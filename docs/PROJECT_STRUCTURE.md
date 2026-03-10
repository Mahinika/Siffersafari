# Project Structure (Reference)

Denna dokument mappning projektets foler-layout och namngivningskonventioner.

---

## Root Directory

```
<repo-root>/
├─ lib/                          ← SOURCE CODE (Dart/Flutter)
├─ test/                         ← UNIT TESTS
├─ integration_test/             ← END-TO-END TESTS
├─ android/                      ← ANDROID-SPECIFIC CONFIG
├─ assets/                       ← PRODUCTION ASSETS (bilder, ljud)
├─ artifacts/                    ← GENERATED/DRAFT ASSETS (inte commitat)
├─ scripts/                      ← UTILITY SCRIPTS (generation, deployment)
├─ docs/                         ← DOCUMENTATION (denna folder!)
├─ .github/                      ← GITHUB CONFIG (CI/CD, workflows)
├─ .vscode/                      ← VS CODE CONFIG
├─ pubspec.yaml                  ← DEPENDENCY MANIFEST
├─ analysis_options.yaml         ← LINT RULES
├─ pubspec.lock                  ← LOCKED VERSIONS (auto-generated, committed)
├─ README.md                     ← PROJECT OVERVIEW
├─ docs/GETTING_STARTED.md       ← TUTORIAL: first steps
├─ docs/CONTRIBUTING.md          ← HOW-TO: QA & commits
├─ copilot-instructions.md       ← Copilot config
└─ (andra root .md filer)        ← arkiverad dokumentation
```

---

## lib/ (Source Code)

**Arkitektur:** Clean Architecture (Domain Drive Design) + Riverpod state management

```
lib/
├─ main.dart                          ← APP ENTRYPOINT
│
├─ core/                              ← APP CORE (Flutter-aware)
│  ├─ config/                         ├─ Feature flags, difficulty rules, app config
│  ├─ constants/                      ├─ App constants (t.ex. app name)
│  ├─ di/                             ├─ Dependency injection (GetIt)
│  │  └─ injection.dart
│  ├─ providers/                      ├─ Riverpod providers (state/services)
│  ├─ services/                       ├─ App services (QuestionGenerator, AudioService, etc.)
│  ├─ theme/                          ├─ Theme/tokens
│  └─ utils/                          └─ Små utilities
│
├─ domain/                            ← DOMAIN (UI-agnostic)
│  ├─ constants/
│  ├─ entities/                       ├─ Core entities (Question, QuizSession, UserProgress, ...)
│  ├─ enums/                          ├─ AgeGroup, DifficultyLevel, OperationType, AppTheme, ...
│  └─ services/                       └─ Pure domain services (ParentPinService, FeedbackService, ...)
│
├─ data/                              ← DATA IMPLEMENTATION
│  └─ repositories/                   └─ Persistence (Hive/LocalStorage)
│
└─ presentation/                      ← UI LAYER
   ├─ dialogs/                        ├─ Reusable dialog components
   ├─ screens/                        ├─ Full-page views
   │  ├─ app_entry_screen.dart        ├─ Initial routing/gate logic
   │  ├─ launch_splash_gate.dart      ├─ Splash screen
   │  ├─ onboarding_screen.dart       ├─ Child onboarding flow (3-step)
   │  ├─ first_run_setup_screen.dart  ├─ Settings on first run
   │  ├─ profile_picker_screen.dart   ├─ Select child profile
   │  ├─ home_screen.dart             ├─ Main hub with story progress
   │  ├─ quiz_screen.dart             ├─ Quiz gameplay
   │  ├─ results_screen.dart          ├─ Quiz results + story reveal
   │  ├─ story_map_screen.dart        ├─ Visual story progression map
   │  ├─ settings_screen.dart         ├─ Child settings/theme choice
   │  ├─ parent_pin_screen.dart       ├─ PIN entry to parent mode
   │  ├─ pin_recovery_screen.dart     ├─ Security question for PIN reset
   │  ├─ parent_dashboard_screen.dart ├─ Parent dashboard/statistics
   │  └─ privacy_policy_screen.dart   └─ Privacy policy view
   └─ widgets/                        ├─ Reusable UI components
      ├─ answer_button.dart
      ├─ question_card.dart
      ├─ progress_indicator_bar.dart
      ├─ theme_mascot.dart            ├─ Lottie-based character animation
      ├─ story_progress_card.dart     ├─ Story progression UI
      └─ themed_background_scaffold.dart
```

---

## test/ (Unit Tests)

```
test/
├─ test_utils.dart                             ├─ Shared test helpers (mocks, DI setup)
├─ unit/
│  ├─ audits/
│  │  ├─ offline_only_audit_test.dart
│  │  └─ mix_distribution_audit_test.dart
│  ├─ logic/
│  │  ├─ difficulty_config_operations_test.dart
│  │  ├─ difficulty_config_grade_test.dart
│  │  ├─ difficulty_config_ranges_test.dart
│  │  ├─ difficulty_config_helpers_test.dart
│  │  ├─ adaptive_difficulty_test.dart
│  │  ├─ spaced_repetition_test.dart
│  │  └─ quiz_progression_edge_cases_test.dart
│  └─ services/
│     ├─ achievement_service_test.dart
│     ├─ parent_pin_service_test.dart
│     ├─ profile_backup_service_test.dart
│     ├─ story_progression_service_test.dart
│     └─ quest_progression_service_test.dart
└─ widget/
   ├─ app_home_test.dart
   ├─ app_quiz_flow_test.dart
   ├─ app_results_test.dart
   ├─ app_parent_mode_test.dart
   └─ app_onboarding_test.dart
```

**Namngivning:** `[Unit/Widget] Feature – description` (t.ex. `Unit – Adaptive difficulty step increase on streak`)

---

## integration_test/ (E2E Tests)

```
integration_test/
├─ test_utils.dart                  └─ Shared utilities (backOnce, waitForText, etc.)
├─ app_smoke_test.dart              ├─ Smoke test: onboarding → home → quiz → results
├─ parent_features_test.dart        ├─ Parent mode: PIN, profile reset
├─ parent_pin_security_question_flow_test.dart ├─ PIN recovery via security question
└─ screenshots_test.dart            └─ Screenshot generation för assets/artifacts
```

---

## assets/ (Production Assets)

**Regel:** Endast godkänd, production-ready content

```
assets/
├─ animations/
│  ├─ celebration.json             ├─ Produktgodkänd Lottie-animation
│  └─ ...                          └─ Fler godkända Lottie-filer
│
├─ images/
│  ├─ themes/
│  │  ├─ jungle/
│  │  │  ├─ background.png          ├─ Tema-bakgrund
│  │  │  ├─ quest_hero.png          ├─ Större illustration
│  │  │  └─ character_v2.png        └─ Statisk illustration (ej mascot-animation)
│  │  └─ space/
│  │     ├─ background.png
│  │     ├─ quest_hero.png
│  │     └─ character.png
│
└─ sounds/
   ├─ background_music.wav          ← PLAN: Konvertera till MP3
   ├─ celebration.wav               ← PLAN: Konvertera till MP3
   ├─ correct.wav                   ← PLAN: Konvertera till MP3
   ├─ wrong.wav                     ← PLAN: Konvertera till MP3
   ├─ click.wav                     ← PLAN: Konvertera till MP3
   └─ CONVERT_TO_MP3.md             ← Instructions
```

**.gitignore regel:** 
```
!assets/images/**/*    # Bilder commitas
!assets/sounds/**/*    # Ljud commitas
# (WAV-backup-filer är ignorerade)
```

---

## artifacts/ (Draft/Generated Assets)

**Regel:** Inte commitat till Git (ligger i `.gitignore`)

```
artifacts/
├─ screenshots/                     ├─ Integration test screenshots
│  ├─ home_screen_1.png             │
│  ├─ quiz_screen_2.png             │
│  └─ ...                           │
```

---

## scripts/ (Utility Scripts)

```
scripts/
├─ flutter_pixel6.ps1               ├─ Deploy & run på Pixel_6 emulator
├─ check_sound_assets.ps1           ├─ Validate audio files
├─ convert_wav_to_mp3.ps1           ├─ Audio format conversion
├─ extract_integration_screenshots.ps1 ├─ Export screenshots
├─ generate_android_launcher_icons.dart ├─ Icon generation
├─ generate_sfx_wav.dart            ├─ Sound effect generation
```

---

## android/ (Android-Specific)

```
android/
├─ app/
│  ├─ build.gradle.kts              ├─ Build config
│  ├─ src/
│  │  └─ main/
│  │     ├─ AndroidManifest.xml     ├─ Manifest
│  │     └─ res/
│  │        ├─ mipmap-*/
│  │        │  └─ ic_launcher.png   ├─ App icon (different sizes)
│  │        └─ values/
│  │           └─ strings.xml       ├─ Translations
│  │
│  └─ ... (gradle build system)
│
├─ gradle/
├─ settings.gradle.kts
└─ key.properties                   ← HEMLIG (SigningKey för Play Store)
                                     └─ NOT COMMITTED
```

---

## .github/ (CI/CD)

```
.github/
├─ workflows/
│  ├─ flutter.yml                   ├─ Main CI: analyze + test
│  └─ release-guard.yml             ├─ Pre-release validation
│
└─ prompts/
   └─ siffersafari-team.prompt.md ├─ Copilot instructions
```

---

## docs/ (Documentation, Diátaxis Framework)

```
docs/
├─ README.md                        ├─ NAVIGATION HUB
├─
├─ SETUP_ENVIRONMENT.md             ├─ TUTORIAL: Detailed env setup
├─ DEPLOY_ANDROID.md                ├─ HOW-TO: Build & release APK
├─ ADD_FEATURE.md                   ├─ HOW-TO: Adding features step-by-step
├─ ASSET_GENERATION.md              ├─ HOW-TO: Generate graphics/sound
├─
├─ ARCHITECTURE.md                  ├─ REFERENCE: System design
├─ SERVICES_API.md                  ├─ REFERENCE: Service interfaces
├─ PROJECT_STRUCTURE.md             ├─ REFERENCE: Folder layout (denna fil!)
├─
├─ DECISIONS_LOG.md                 ├─ EXPLANATION: Design choices
├─ KUNSKAPSNIVA_PER_AK.md           ├─ EXPLANATION: Pedagogisk mapping
├─ CHARACTER_ANIMATIONS.md          ├─ EXPLANATION: Animation pipeline
│
└─ PARENTS_TEACHERS_GUIDE.md        ├─ (separate audience: föräldrar/lärare)
```

---

## Naming Conventions

### Dart/Flutter

| Typ | Format | Exempel |
|-----|--------|---------|
| Fil | `snake_case.dart` | `user_progress.dart` |
| Mapp | `snake_case/` | `presentation/` |
| Klass (abstract) | `AbstractService` | `QuizRepository` |
| Klass (impl) | `ServiceImpl` | `QuizRepositoryImpl` |
| Enum | `PascalCase` | `Difficulty` |
| Constant | `kPascalCase` | `kDefaultFontSize` |
| Variable | `camelCase` | `currentScore` |
| Riverpod provider | `<feature>Provider` | `quizProvider` |

### Git & GitHub

| Typ | Format | Exempel |
|-----|--------|---------|
| Branch | `feature/<name>` eller `fix/<name>` | `feature/expert-mode` |
| Commit | Conventional Commits | `feat: add expert difficulty` |
| Tag | `v<version>` | `v1.0.2` |

---

## Common Paths

Snabbrefenser för ofta använda paths:

```bash
# App entry & routing
lib/main.dart                                 # Main entrypoint
lib/presentation/screens/app_entry_screen.dart # Initial routing/gate
lib/presentation/screens/launch_splash_gate.dart # Splash screen
lib/presentation/screens/home_screen.dart      # Main hub

# Story progression
lib/core/providers/story_progress_provider.dart
lib/core/services/story_progression_service.dart
lib/presentation/screens/story_map_screen.dart

# Quiz & difficulty
lib/core/services/question_generator_service.dart
lib/core/config/difficulty_config.dart
lib/domain/services/adaptive_difficulty_service.dart
lib/presentation/screens/quiz_screen.dart

# Parent/admin
lib/presentation/screens/parent_dashboard_screen.dart
lib/presentation/screens/parent_pin_screen.dart
lib/domain/services/parent_pin_service.dart

# Data & persistence
lib/data/repositories/local_storage_repository.dart
lib/core/services/achievement_service.dart

# Tests (unit + widget)
test/unit/logic/adaptive_difficulty_test.dart
test/unit/services/achievement_service_test.dart
test/widget/app_home_test.dart
test/widget/app_quiz_flow_test.dart

# Integration tests
integration_test/app_smoke_test.dart
integration_test/screenshots_test.dart

# Assets (Lottie, images, sounds)
assets/animations/celebration.json
assets/images/themes/jungle/background.png
assets/images/themes/space/background.png
assets/sounds/correct.wav

# Build & deployment
pubspec.yaml
android/app/build.gradle.kts
scripts/flutter_pixel6.ps1
scripts/extract_integration_screenshots.ps1

# Configuration & CI
analysis_options.yaml
.github/workflows/flutter.yml
.github/workflows/build.yml
copilot-instructions.md
```

---

## Filstorlek Targets

| Typ | Target | Aktuell |
|-----|--------|---------|
| Total `assets/` | < 20 MB | ~5 MB |
| APK (debug) | < 100 MB | ~80 MB |
| APK (release) | < 50 MB | ~40 MB |
| `lib/` kod | < 500 KB | ~300 KB |

---

**Se även:** [README.md](README.md) för navigation och [ARCHITECTURE.md](ARCHITECTURE.md) för designöversikt.
