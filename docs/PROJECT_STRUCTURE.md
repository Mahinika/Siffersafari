# Project Structure (Reference)

Denna dokument mappning projektets foler-layout och namngivningskonventioner.

---

## Root Directory

```
d:\Projects\Personal\Siffersafari/
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
├─ pubspec.lock                  ← LOCKED VERSIONS (auto-generated, .gitignored)
├─ README.md                     ← PROJECT OVERVIEW
├─ GETTING_STARTED.md            ← TUTORIAL: first steps
├─ CONTRIBUTING.md               ← HOW-TO: QA & commits
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
├─ core/                              ← CORE UTILITIES
│  ├─ service_locator.dart            ├─ Dependencies (GetIt)
│  ├─ hive_setup.dart                 ├─ Hive initialization
│  └─ theme/
│     ├─ app_colors.dart              ├─ Color constants
│     ├─ app_text_styles.dart         ├─ Typography
│     └─ app_theme.dart               └─ Theme definition
│
├─ domain/                            ← BUSINESS LOGIC (unaware of UI)
│  ├─ models/                         ├─ Data classes (Difficulty, UserProfile, etc.)
│  │  ├─ difficulty.dart              │
│  │  ├─ user_progress.dart           │
│  │  └─ achievement.dart             │
│  │
│  ├─ entities/                       ├─ Hive-persistent data (decorated with @HiveType)
│  │  ├─ user_progress.dart           │
│  │  └─ ...                          │
│  │
│  ├─ repositories/ (abstract)        ├─ Interfaces (contracts)
│  │  ├─ quiz_repository.dart         │
│  │  ├─ profile_repository.dart      │
│  │  └─ achievement_repository.dart  │
│  │
│  └─ services/ (abstract)            ├─ Business services
│     ├─ adaptive_difficulty_service.dart  │
│     ├─ quiz_progression_service.dart     │
│     ├─ achievement_service.dart          │
│     ├─ spaced_repetition_service.dart    │
│     └─ ...                               │
│
├─ data/                              ← DATA IMPLEMENTATION
│  ├─ repositories/ (impl)            ├─ Concrete repositories (Hive, API, etc.)
│  │  ├─ quiz_repository_impl.dart    │
│  │  ├─ profile_repository_impl.dart │
│  │  └─ achievement_repository_impl.dart
│  │
│  ├─ services/ (impl)                ├─ Concrete services
│  │  ├─ adaptive_difficulty_service.dart
│  │  ├─ quiz_progression_service.dart
│  │  └─ ...
│  │
│  └─ hive_adapters/                 ├─ Hive type adapters (auto-generated)
│     ├─ user_progress_adapter.g.dart │
│     └─ ...                          │
│
└─ presentation/                      ← UI LAYER
   ├─ app/                            ├─ App-level widgets
   │  ├─ app_widget.dart              │
   │  └─ ...                          │
   │
   ├─ screens/                        ├─ Full-page views (routed)
   │  ├─ home_screen.dart             │
   │  ├─ quiz_screen.dart             │
   │  ├─ parent_mode_screen.dart      │
   │  └─ ...                          │
   │
   ├─ widgets/                        ├─ Reusable UI components
   │  ├─ difficulty_selector_widget.dart
   │  ├─ quiz_card_widget.dart        │
   │  ├─ mascot_view.dart             │  (character animations)
   │  ├─ achievement_badge.dart       │
   │  └─ ...                          │
   │
   ├─ providers/ (Riverpod)           ├─ State providers
   │  ├─ current_profile_provider.dart │
   │  ├─ quiz_provider.dart           │
   │  ├─ achievement_provider.dart    │
   │  └─ ...                          │
   │
   └─ routes/                         ├─ Navigation (om router används)
      ├─ app_router.dart              │
      └─ ...                          │
```

---

## test/ (Unit Tests)

```
test/
├─ offline_only_audit_test.dart                ├─ Verificera offline-only arkitektur
├─ curriculum_logic_coverage_test.dart         ├─ Curriculum mappning (Åk 1-9)
├─ difficulty_config_test.dart                 ├─ Difficulty levels & progression
├─ mix_distribution_audit_test.dart            ├─ Addition/subtraction distribution
├─ adaptive_difficulty_service_test.dart       ├─ Service-specifikt
├─ achievement_service_test.dart               ├─ Service-specifikt
├─ spaced_repetition_service_test.dart         ├─ Service-specifikt
├─ quiz_progression_service_test.dart          ├─ Service-specifikt
├─ parent_pin_service_test.dart                ├─ Parent mode PIN system
├─ profile_backup_service_test.dart            ├─ Backup/restore
│
├─ app_widget_flows_test.dart                  ├─ UI Integration tests
├─ quiz_progression_edge_cases_test.dart       ├─ Edge cases
└─ accessibility_widgets_test.dart             └─ Accessibility check
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
├─ comfyui/                         ├─ ComfyUI-genererade bilder
│  ├─ txt2img_<date>/               │
│  │  ├─ mascot_0.png               │
│  │  ├─ mascot_1.png               │
│  │  └─ ...                        │
│  │
│  ├─ img2img_<date>/               │
│  │  └─ mascot_jumping_0.png       │
│  │
│  └─ animations/
│     ├─ idle_000.png
│     ├─ idle_001.png
│     └─ ...
│
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
├─ generate_character_v2_animation_frames.ps1 ├─ Character sprites
├─ generate_character_v2_pose_pack.ps1 ├─ Pose variations
├─ generate_images_comfyui.dart     ├─ ComfyUI API client
├─ generate_sfx_wav.dart            ├─ Sound effect generation
│
└─ comfyui/
   ├─ start_comfyui.ps1             ├─ Start server
   ├─ bench_comfyui.ps1             ├─ Performance benchmark
   ├─ README.md                     ├─ Documentation
   ├─ prompt_packs/                 │
   │  ├─ badges/                    │
   │  ├─ jungle_backgrounds/        │
   │  └─ space_backgrounds/         │
   └─ workflows/
      ├─ txt2img_api.json           ├─ Text-to-image
      └─ img2img_color_api.json     └─ Image-to-image
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
├─ COMFYUI_STRATEGI.md              ├─ EXPLANATION: Image AI strategy
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
# GUI
lib/presentation/app/app_widget.dart          # Main app
lib/presentation/screens/home_screen.dart     # Home

# Business logic
lib/domain/services/adaptive_difficulty_service.dart
lib/domain/services/achievement_service.dart

# Data access
lib/data/repositories/quiz_repository_impl.dart
lib/data/repositories/profile_repository_impl.dart

# Tests
test/curriculum_logic_coverage_test.dart
test/achievement_service_test.dart

# Assets
assets/images/themes/jungle/background.png
assets/sounds/correct.wav

# Scripts
scripts/flutter_pixel6.ps1
scripts/generate_images_comfyui.dart

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
