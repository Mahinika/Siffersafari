# Asset Generation (How-To)

This guide describes how to generate, review and promote assets in Siffersafari.

Core rule:
- only approved production assets belong in `assets/`
- previews, experiments and review material belong in `artifacts/`

## Quick Start

```bash
flutter pub get

python tools/create_character.py --name "Mira" --brief "space explorer with teal jacket and gold backpack"
python tools/refresh_character.py --slug loke
# Regenerate baseline kid-friendly SFX WAVs into `assets/sounds/`.
dart run scripts/generate_sfx_wav.dart --out assets/sounds

# Generate Android launcher icons (writes into `android/app/src/main/res/`).
# By default reads `assets/images/app_icon/icon_source.png`.
dart run scripts/generate_android_launcher_icons.dart
```

## Python prerequisites
`tools/create_character.py` and `tools/pipeline.py` require `PyYAML`:
```bash
pip install pyyaml
```

## AI-Driven Asset Pipeline

### Automated generators

```bash
# Create a fully registered SVG-first character from a short brief
python tools/create_character.py --name "Mira" --brief "space explorer with teal jacket and gold backpack"
# -> assets/characters/mira/config/*.json
# -> assets/characters/mira/svg/*.svg
# -> artifacts/mira_rive_blueprint.json
# -> artifacts/MIRA_RIVE_GUIDE.md
# -> specs/*.yaml
# -> artifacts/asset_pipeline_manifest.json
# -> lib/gen/assets.g.dart

# Refresh an existing generator-backed character from its current config
python tools/refresh_character.py --slug loke
# -> updates assets/characters/loke/config/loke_visual_spec.json
# -> updates assets/characters/loke/svg/*.svg
# -> updates artifacts/loke_rive_blueprint.json
# -> updates artifacts/LOKE_RIVE_GUIDE.md
# -> updates artifacts/asset_pipeline_manifest.json
# -> updates lib/gen/assets.g.dart

# Orchestrate mascot/UI pipeline + manifest + typed asset access
python tools/pipeline.py build-all
# -> artifacts/asset_pipeline_manifest.json
# -> lib/gen/assets.g.dart

# Build only approved UI effects
python tools/pipeline.py build-lottie
# -> assets/ui/lottie/*.json

# Validate generated asset content against style contract
python tools/pipeline.py lint-assets --strict
# -> validates SVG/Lottie against specs/style_contract.yaml
```

### Output classification

| Asset type | Generator | Output | Status |
| --- | --- | --- | --- |
| New SVG-first character | `tools/create_character.py` | character folder + specs + blueprint + codegen | Fully automated |
| Refresh existing SVG-first character | `tools/refresh_character.py` | regenerated visual spec + SVG assets + blueprint + codegen | Safe refresh, preserves animation spec |
| Mascot + UI pipeline | `tools/pipeline.py build-all` | mascot SVG/Lottie/Rive blueprint + manifest/codegen | Canonical repo pipeline |
| Lottie UI effects | `tools/pipeline.py build-lottie` | confetti, stars, success_pulse, error_shake | Approved runtime UI effects |

Important limitation:
- no script in this repo produces a production-ready `.riv` automatically
- this is acceptable because the default app runtime now uses generated SVG/composite assets and does not require a `.riv`

## Recommended Workflow

1. Create a new character from a short brief, or generate/update candidate assets
2. Review them in `artifacts/` or in dedicated preview surfaces
3. Run `python tools/pipeline.py build-all` when mascot/UI generated outputs are part of the change
4. Run `python tools/pipeline.py validate --strict`, `python tools/pipeline.py lint-assets --strict` and `python tools/pipeline.py manifest`
5. Verify in app
6. Commit only the approved runtime artifacts and their source specs/scripts

## Style Contract

- `specs/style_contract.yaml` defines machine-readable style gates for generated assets.
- `python tools/pipeline.py lint-assets --strict` enforces these rules for SVG and Lottie outputs.
- Promotion and CI now run this lint step before tests/promote.
- `python tools/pipeline.py lint-assets --strict --warn-only` can be used during staged rollout.

### Rollout controls

- `enforcement.default_warn_only` toggles default local behavior for lint command.
- `pilot.enabled` + `pilot.character_ids`/`pilot.effect_ids` limits checks to a pilot scope.
- `enforcement.fallback_policy: keep_last_known_good_assets` means failed lint stops promotion before asset copy.
- CI writes `artifacts/asset_lint_report.json` and publishes it as artifact + step summary.

## Runtime Policy For The Mascot

- Use the generated composite SVG as the default runtime character path
- Use `assets/ui/lottie/` for approved UI effects only
- Treat `.riv` files as optional enhancement assets only when explicitly approved and enabled
- Do not use preview files as hidden runtime fallback in product UI
- Simple mascot feedback motion should stay automatable in Flutter/SVG rather than depend on manual editor exports

## Organize Approved Assets

```bash
cp artifacts/jungle/background_v3.png assets/images/themes/jungle/background.png
cp artifacts/mascot/mascot_character.riv assets/characters/mascot/rive/mascot_character.riv
cp artifacts/ui/confetti.json assets/ui/lottie/confetti.json
```

Note:
- copying a `.riv` into `assets/characters/mascot/rive/` is only valid after it has been manually verified to contain artboard `Mascot` and state machine `MascotStateMachine`

## Pre-flight Checks

```bash
rg "assets/images|assets/characters|assets/ui/lottie|assets/sounds" pubspec.yaml
Get-ChildItem assets -Recurse | Measure-Object -Property Length -Sum
python tools/pipeline.py validate --strict
python tools/pipeline.py lint-assets --strict
flutter analyze
flutter test
```

## Automated Promotion Workflow

Use the **promotion script** for end-to-end automation:

```powershell
# New character
.\scripts\promote_assets.ps1 -Workflow NewCharacter -CharacterName "Mira" -CharacterBrief "space explorer"

# Update existing character
.\scripts\promote_assets.ps1 -Workflow UpdateCharacter -CharacterSlug loke

# Lottie/SFX only
.\scripts\promote_assets.ps1 -Workflow LottieSFX
```

The script runs all phases automatically:
1. **Generate** - character source files plus canonical pipeline steps
2. **Validate** - spec contract checks + manifest update
3. **Quality Gates** - analyze + targeted tests + full test suite
4. **Promote** - confirm expected runtime outputs already landed in canonical asset paths
5. **Report** - show next manual steps

### Options
- `-SkipQA` : Skip all QA tests (for preview/debug only)
- `-DryRun` : Show what would happen without executing

### After Promotion
```powershell
# Verify only expected files changed
.\scripts\verify_git_changes.ps1

# Review and commit
git add .
git commit -m "Character/assets: <brief description>"
git push
```

---

## Manual Workflow (if not using script)

Use the matching checklist below for reference or when not using the automated script.

### A) New Character

1. Generate candidate character:

```bash
python tools/create_character.py --name "<Name>" --brief "<brief>" --skip-pipeline
```

2. Regenerate dependent mascot/UI assets through the canonical pipeline:

```bash
python tools/pipeline.py build-all
```

3. Validate runtime paths and mascot integration:

```bash
flutter analyze
flutter test test/unit/assets/generated_asset_paths_test.dart
flutter test test/widget/mascot_character_test.dart
```

4. Run broader regression pass:

```bash
flutter test
```

5. Promotion + hygiene:
- Ensure runtime composite exists at `assets/characters/<slug>/svg/<slug>_composite.svg`.
- Keep only production assets in `assets/`; keep previews/blueprints/references in `artifacts/`.
- Confirm only expected files changed before PR.

### B) Update Existing Character

1. Refresh from current config:

```bash
python tools/refresh_character.py --slug <slug> --skip-pipeline
```

2. Rebuild mascot/UI outputs through the canonical pipeline:

```bash
python tools/pipeline.py build-all
```

3. Verify gates:

```bash
flutter analyze
flutter test test/unit/assets/generated_asset_paths_test.dart
flutter test test/widget/mascot_character_test.dart
```

4. If a `.riv` runtime asset is touched, verify manually and run:

```powershell
scripts/verify_mascot_rive_runtime.ps1
```

5. Confirm PR contains only intended runtime/spec/script changes.

### C) Only Lottie/SFX

1. Regenerate changed asset class:

```bash
python tools/pipeline.py build-lottie
dart run scripts/generate_sfx_wav.dart --out assets/sounds
```

2. Validate app behavior and no path regressions:

```bash
flutter analyze
flutter test test/unit/assets/generated_asset_paths_test.dart
flutter test
```

3. Placement and scope:
- Lottie runtime files in `assets/ui/lottie/`.
- Approved production sounds in `assets/sounds/`.
- Any exploratory exports stay in `artifacts/`.
