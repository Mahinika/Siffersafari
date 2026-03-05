# Adding a Feature (How-To Guide)

Denna guide visar **steg-för-steg** hur du lägger till en ny feature i Siffersafari.

Exempel: Vi lägger till en ny quiz-svårighetsgrad kallad "Expert Mode".

---

## Overview: Feature Development Pipeline

```
1. Plan             (Vad gör den? Hur integreras den?)
2. Implement        (Ändra kod, skapa tester)
3. QA               (flutter analyze, flutter test)
4. Commit & Push    (Git-historia ren)
5. Deploy           (Manual test på emulator, ev. Play Store)
```

---

## 1. Planning Phase

### 1.1 Define the Feature

Beskriv i ett par meningar:
- **What:** "Expert Mode - 3rd difficulty level för Åk 7-9"
- **Why:** "Högpresterande barn behöver högre svårighet"
- **Scope:** "Config only - ingen ny UI ännu"

### 1.2 Identify Touch Points

Research: Vilka filer behöver ändringar?

**För Expert Mode:**
```
lib/domain/models/difficulty.dart          → Add EXPERT enum
lib/data/repositories/quiz_repository.dart → Add Expert questions
lib/domain/services/adaptive_difficulty_service.dart → Handle Expert progression
test/                                       → Add tests
```

### 1.3 Create a Branch (optional men recommended)

```bash
git checkout -b feature/expert-mode
```

---

## 2. Implementation Phase

### Step 1: Update Models

Öppna `lib/domain/models/difficulty.dart`:

```dart
enum Difficulty {
  easy,
  medium,
  hard,
  expert,  // ← Ny
}
```

### Step 2: Add Data

Öppna `lib/data/repositories/quiz_repository.dart`:

Lär till Expert-level questions (exempel):

```dart
static const Map<Difficulty, List<String>> questions = {
  Difficulty.easy: ["1+1=?", ...],
  Difficulty.medium: ["5*5=?", ...],
  Difficulty.hard: ["99/3=?", ...],
  Difficulty.expert: ["(√144)+(3²)=?", ...],  // ← Ny
};
```

### Step 3: Update Business Logic

Öppna `lib/domain/services/adaptive_difficulty_service.dart`:

```dart
Difficulty _calculateNextDifficulty(...) {
  // Befintlig logik...
  
  if (currentScore > 95 && points >= 500) {
    return Difficulty.expert;  // ← Ny
  }
  
  // resten...
}
```

### Step 4: Update UI (if needed)

Om du behöver visa "Expert Mode" någonstans, uppdatera relevant UI-widget.

**Exempel:** `lib/presentation/widgets/difficulty_selector_widget.dart`

```dart
Text(
  difficulty.name,
  style: TextStyle(
    fontSize: difficulty == Difficulty.expert ? 16 : 14,  // Expert mode större text
  ),
)
```

---

## 3. Testing Phase

### Write Unit Tests

Skapa `test/expert_mode_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/domain/models/difficulty.dart';

void main() {
  group('Expert Mode', () {
    test('Expert questions exist', () {
      final questions = QuizRepository.getQuestions(Difficulty.expert);
      expect(questions.isNotEmpty, true);
    });

    test('Expert questions are harder than Hard', () {
      final expertQs = QuizRepository.getQuestions(Difficulty.expert);
      final hardQs = QuizRepository.getQuestions(Difficulty.hard);
      
      // Example: Expert kan ha 3-digit multiplication
      expect(
        expertQs.any((q) => q.contains('√') || q.contains('³')),
        true,
        reason: 'Expert should have advanced operations',
      );
    });
  });
}
```

### Run Tests

```bash
# Bara denna test
flutter test test/expert_mode_test.dart

# Eller kolla alla tester
flutter test
```

**Förväntat:** Alla tester passa.

---

## 4. QA Phase

### 4.1 Static Analysis

```bash
flutter analyze
```

**Förväntat:** "No issues found!"

Om linters-fel dyker upp:
```bash
# Automatisk fix
dart fix --apply
```

### 4.2 Full Test Suite

```bash
flutter test
```

**Förväntat:** Alla 85+ tester passa (inklusive dina nya).

### 4.3 Manual Smoke Test

Starta appen på emulator och testa manuellt:

```bash
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync
```

**Test checklist:**
- [ ] Appen startar
- [ ] Gamla difficultyes fungerar fortfarande
- [ ] Expert Mode är tillgänglig efter vissa poäng
- [ ] Expert Mode frågor är svårare
- [ ] Achievements sparas offline

---

## 5. Commit & Push Phase

### Clean Git History

Se till att du bara har relevanta files:

```bash
git status

# Förväntat output (ungefär):
# modified:   lib/domain/models/difficulty.dart
# modified:   lib/data/repositories/quiz_repository.dart
# modified:   lib/domain/services/adaptive_difficulty_service.dart
# new file:   test/expert_mode_test.dart
```

### Commit

```bash
git add .
git commit -m "feat: add Expert Mode difficulty level

- Added Difficulty.expert enum value
- Added 50+ Expert-level questions to quiz database
- Updated adaptive_difficulty_service to unlock Expert at 95%+ score
- Added unit tests for Expert Mode questions

Closes #42 (if applicable)"
```

**Format:** Använd [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` för nya features
- `fix:` för bugfixes
- `refactor:` för code reorganization
- `test:` för test-ändringar
- `docs:` för dokumentation
- `chore:` för inte-funktionell ändringar

### Push

```bash
git push origin feature/expert-mode
```

Eller direkt till main (om no-branch-workflow):

```bash
git push origin main
```

---

## 6. Deploy Phase

### Prepare for Release

Se [DEPLOY_ANDROID.md](DEPLOY_ANDROID.md) för full process.

Kort:
```bash
# Uppdatera version i pubspec.yaml
version: 1.0.3+6  # Var 1.0.2+5 innan

# Commit
git commit -m "chore: bump version to 1.0.3"

# Build release APK
flutter build apk --release

# Upload to Play Store
# (google play console UI)
```

---

## Example Checklist for Expert Mode

```markdown
- [x] Models updated (Difficulty enum)
- [x] Questions added to database
- [x] Business logic updated (progression)
- [x] UI updated (if needed)
- [x] Unit tests written and passing
- [x] flutter analyze passing
- [x] Manual smoke test on Pixel_6
- [x] Committed with clear message
- [x] Pushed to GitHub
- [ ] Release notes prepared (for Play Store)
- [ ] Version bumped (if releasing)
- [ ] Built APK and tested on real device
```

---

## Common Patterns

### Pattern 1: Add a New Service

Se [SERVICES_API.md](SERVICES_API.md) för hur services struktureras.

**Steps:**
1. Create `lib/domain/services/my_service.dart`
2. Implement interface (abstract class)
3. Create `lib/data/services/my_service_impl.dart` (impl)
4. Register i GetIt: `lib/core/service_locator.dart`
5. Use via `sl<MyService>()`

### Pattern 2: Add Persistent Data

För data som behöver sparas offline:

1. Create entity: `lib/domain/entities/my_entity.dart`
2. Use Hive: `@HiveType(typeId: N)` och `@HiveField(0)`
3. Create repository: `lib/data/repositories/my_repository.dart`
4. Add to Hive adapter generation: `build_runner build`

---

## Troubleshooting

### "Test fails with 'class not found'"
- **Orsak:** Import-sökväg fel
- **Lösning:** Kontrollera import i test-fil
  ```dart
  import 'package:siffersafari/domain/models/difficulty.dart';
  ```

### "flutter analyze fails with lint error"
- **Lösning:**
  ```bash
  dart fix --apply  # Automatisk fix
  ```

### "git commit blocked by pre-push checks"
- **Orsak:** GitHub Actions kanske testar innan du pushar
- **Lösning:** Kör `flutter test` lokalt innan push

---

## More Help

- **Architecture questions?** Se [ARCHITECTURE.md](ARCHITECTURE.md)
- **Service API?** Se [SERVICES_API.md](SERVICES_API.md)
- **Code standards?** Se [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Folder structure?** Se [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
