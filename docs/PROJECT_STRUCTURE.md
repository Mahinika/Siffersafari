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
│  ├─ services/                       ├─ App services (t.ex. QuestionGenerator)
│  ├─ theme/                          ├─ Theme/tokens
│  └─ utils/                          └─ Små utilities
│
├─ domain/                            ← DOMAIN (UI-agnostic)
│  ├─ constants/
│  ├─ entities/                       ├─ Core entities (Question, QuizSession, ...)
│  ├─ enums/                          ├─ AgeGroup, DifficultyLevel, OperationType, ...
│  └─ services/                       └─ Pure domain services
│
├─ data/                              ← DATA IMPLEMENTATION
│  └─ repositories/                   └─ Persistence (Hive/LocalStorage)
│
└─ presentation/                      ← UI LAYER
   ├─ dialogs/
   ├─ screens/                        ├─ Full-page views
   │  ├─ app_entry_screen.dart
   │  ├─ home_screen.dart
   │  ├─ onboarding_screen.dart
   │  ├─ quiz_screen.dart
   │  ├─ results_screen.dart
   │  ├─ parent_pin_screen.dart
   │  └─ parent_dashboard_screen.dart
   └─ widgets/                        ├─ Reusable UI components
      ├─ answer_button.dart
      ├─ question_card.dart
      ├─ progress_indicator_bar.dart
      ├─ mascot_view.dart
      └─ themed_background_scaffold.dart
```

---

## test/ (Unit Tests)

```
test/
├─ test_utils.dart                             ├─ Shared test helpers/mocks
├─ unit/
│  ├─ audits/
│  │  ├─ offline_only_audit_test.dart
│  │  └─ mix_distribution_audit_test.dart
│  ├─ logic/
│  │  ├─ difficulty_config_*_test.dart
│  │  ├─ adaptive_difficulty_test.dart
│  │  ├─ spaced_repetition_test.dart
│  │  └─ quiz_progression_edge_cases_test.dart
│  └─ services/
│     ├─ achievement_service_test.dart
│     ├─ parent_pin_service_test.dart
│     ├─ profile_backup_service_test.dart
│     └─ quest_progression_service_test.dart
└─ widget/
   ├─ app_home_test.dart
   ├─ app_quiz_flow_test.dart
   └─ app_results_test.dart
```

**Namngivning:** `<feature>_test.dart` (wildcard `_test.dart` lookas upp av `flutter test`)

---

## integration_test/ (E2E Tests)

```
integration_test/
├─ app_smoke_test.dart              ├─ Alla app-flöden (home → quiz → result)
├─ parent_features_test.dart        ├─ Parent mode: PIN, profile reset
├─ screenshots_test.dart            ├─ Screenshot generation för Play Store
└─ test_utils.dart                  └─ Shared utilities
```

---

## assets/ (Production Assets)

**Regel:** Endast godkänd, production-ready content

```
assets/
├─ images/
│  ├─ themes/
│  │  ├─ jungle/
│  │  │  ├─ background.png          ├─ Tema-bakgrund
│  │  │  ├─ quest_hero.png          ├─ Större illustration
│  │  │  └─ character.png           └─ Alternativ sprite
│  │  └─ space/
│  │     ├─ background.png
│  │     ├─ quest_hero.png
│  │     └─ character.png
│  │
│  └─ characters/
│     └─ character_v2/
│        └─ idle/
│           ├─ idle_000.png
│           ├─ idle_001.png
│           └─ ... (8 frames)
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
│
└─ mascot_frames/                   └─ Character animation work-in-progress
   ├─ pose_pack_v1/
   └─ ...
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
# App entry
lib/main.dart                                 # Main entrypoint
lib/presentation/screens/app_entry_screen.dart # Initial routing/gate
lib/presentation/screens/home_screen.dart      # Home

# Business logic
lib/domain/services/adaptive_difficulty_service.dart
lib/core/config/difficulty_config.dart
lib/core/services/question_generator_service.dart
lib/core/services/achievement_service.dart

# Data access
lib/data/repositories/local_storage_repository.dart

# Tests
test/unit/logic/curriculum_logic_coverage_test.dart
test/unit/services/achievement_service_test.dart
test/widget/app_quiz_flow_test.dart

# Assets
assets/images/themes/jungle/background.png
assets/sounds/correct.wav

# Scripts
scripts/flutter_pixel6.ps1
scripts/generate_sfx_wav.dart

# Konfigurering
pubspec.yaml
analysis_options.yaml
android/app/build.gradle.kts
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
