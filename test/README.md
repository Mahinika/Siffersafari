# Test Suite Documentation

This document describes the organization, structure, and conventions for the Multiplikation test suite.

## Overview

The test suite contains **83 tests** organized into two main categories:
- **Unit tests** (71 tests) – Logic, services, and audits
- **Widget tests** (12 tests) – UI integration and user flows

All tests run with: `flutter test`

## Directory Structure

```
test/
├── unit/                          # Unit tests (71 tests)
│   ├── logic/                     # Business logic (12 tests)
│   │   ├── adaptive_difficulty_test.dart
│   │   ├── difficulty_config_operations_test.dart
│   │   ├── difficulty_config_grade_test.dart
│   │   ├── difficulty_config_ranges_test.dart
│   │   ├── difficulty_config_helpers_test.dart
│   │   └── quiz_progression_edge_cases_test.dart
│   ├── services/                  # Service layer (51 tests)
│   │   ├── achievement_service_test.dart
│   │   ├── adaptive_difficulty_service_test.dart
│   │   ├── app_settings_service_test.dart
│   │   ├── offline_storage_service_test.dart
│   │   ├── parent_pin_service_test.dart
│   │   ├── profile_backup_service_test.dart
│   │   ├── quest_progression_service_test.dart
│   │   ├── spaced_repetition_service_test.dart
│   │   └── session_sync_service_test.dart
│   └── audits/                    # Verification/audit tests (8 tests)
│       ├── accessibility_widgets_test.dart
│       ├── mix_distribution_audit_test.dart
│       └── offline_only_audit_test.dart
└── widget/                        # Widget tests (12 tests)
    ├── app_home_test.dart
    ├── app_onboarding_test.dart
    ├── app_parent_mode_test.dart
    ├── app_quiz_flow_test.dart
    ├── app_results_test.dart
    └── [other widget tests...]
```

### Directory Purposes

- **`test/unit/logic/`** – Tests for core game mechanics, difficulty progression, and quiz flow logic
- **`test/unit/services/`** – Tests for business services (storage, achievements, parent features, offline sync, etc.)
- **`test/unit/audits/`** – Verification tests that validate system invariants (accessibility compliance, question distribution, offline functionality)
- **`test/widget/`** – Integration tests for user flows and UI behavior

## Test Naming Convention

All tests follow this standardized naming format:

```
[Category] Feature – description
```

### Examples

**Unit Tests:**
- `[Unit] DifficultyConfig – Grade benchmarks`
- `[Unit] AdaptiveDifficultyService – beräknar träffsäkerhet` (calculates hit rate)
- `[Unit] ParentPinService – Change PIN`

**Widget Tests:**
- `[Widget] Quiz – complete full session and replay`
- `[Widget] Parent mode – PIN setup and unlock`
- `[Widget] Onboarding – appears once and is skippable`

### Naming Guidelines

- **Category**: `[Unit]` or `[Widget]` to indicate test type
- **Feature**: Name of the main class/feature being tested
- **Description**: What is being tested (in Swedish or English)
- **Separator**: Use ` – ` (em-dash) between feature and description

## Running Tests

### Run all tests
```bash
flutter test
```

### Run only unit tests
```bash
flutter test test/unit/
```

### Run only widget tests
```bash
flutter test test/widget/
```

### Run only logic tests
```bash
flutter test test/unit/logic/
```

### Run only service tests
```bash
flutter test test/unit/services/
```

### Run only audit tests
```bash
flutter test test/unit/audits/
```

### Run a specific test file
```bash
flutter test test/unit/services/achievement_service_test.dart
```

### Run with specific pattern
```bash
flutter test --name "DifficultyConfig"
```

### Run with coverage
```bash
flutter test --coverage
```

## Test Organization Rationale

### Why split by unit/widget?
- **Unit tests** verify isolated logic without UI framework overhead
- **Widget tests** verify full app integration and user interactions
- Clear separation helps developers find relevant tests quickly

### Why split unit tests into logic/services/audits?
- **Logic**: Core game mechanics that should never break
- **Services**: Testable business logic (storage, sync, achievements)
- **Audits**: System-wide verification (no broken questions, offline-safe code, a11y compliant widgets)

## Writing New Tests

When adding new tests:

1. **Choose the right category:**
   - Single class/function logic → `test/unit/logic/` or `test/unit/services/`
   - UI widget behavior → `test/widget/`
   - System invariants → `test/unit/audits/`

2. **Follow naming convention:**
   ```dart
   group('[Unit] YourFeature – what is tested', () {
     test('specific behavior', () {
       // arrange, act, assert
     });
   });
   ```

3. **Keep tests focused:**
   - One test group per file (or split if file grows beyond ~150 lines)
   - Test one behavior per test
   - Use descriptive test names

4. **Use mocks and fixtures:**
   - Common mocks in each test file (don't share unless reused 3+ times)
   - Keep setup code at top of file

## Test Quality Standards

- All tests must pass before committing: `flutter test`
- All tests must be deterministic (no flakiness)
- Aim for >80% code coverage on core game logic
- Tests should document expected behavior (act as executable specs)

## Troubleshooting

### Tests fail randomly
- Check for Navigator state issues (don't recreate widgets unnecessarily)
- Ensure mocks are properly reset between tests
- Look for race conditions in async code

### Tests take too long
- Profile with `flutter test --concurrency=1` to find slow tests
- Consider moving slow integration tests to `integration_test/` instead

### Coverage gaps
- Run `flutter test --coverage` and check `coverage/lcov.info`
- Focus on high-risk game logic first

---

**Last Updated:** 2026-03-05  
**Total Tests:** 83 (71 unit + 12 widget)
