# Adding a Feature (How-To Guide)

Denna guide visar **steg-för-steg** hur du lägger till en ny feature i Siffersafari.



---



```
1. Plan             (Vad gör den? Hur integreras den?)
2. Implement        (Ändra kod, skapa tester)
3. QA               (flutter analyze, flutter test)
4. Commit & Push    (Git-historia ren)
5. Deploy           (Manual test på emulator, ev. Play Store)
```

---

## 1. Planning Phase


### 1.1 Definiera din feature

Beskriv i ett par meningar:
- **What:** "Ny svårighetsgrad, t.ex. 'Hard'"
- **Why:** "För att utmana elever på högre nivå"
- **Scope:** "Config och logik, UI vid behov"


### 1.2 Identifiera berörda filer

Research: Vilka filer behöver ändras?

**Exempel:**
```
lib/domain/enums/difficulty_level.dart          → Lägg till/ändra svårighetsgrad i enum
lib/core/config/difficulty_config.dart          → Regler: ranges/steps/poäng
lib/core/services/question_generator_service.dart → Generering av frågor per svårighet
lib/domain/services/adaptive_difficulty_service.dart → Progression/logik
lib/presentation/…                              → UI (om svårighet visas)
test/unit/logic/…                               → Uppdatera/lägg till unit tests
```

### 1.3 Create a Branch (optional men recommended)

```bash
git checkout -b feature/expert-mode
```

---

## 2. Implementation Phase


### Steg 1: Uppdatera modeller

Öppna `lib/domain/enums/difficulty_level.dart`:

```dart
enum DifficultyLevel {
  easy,
  medium,
  hard,
}
```

Obs: I projektet är `DifficultyLevel` även annoterad för Hive. Kom ihåg att uppdatera `@HiveField(...)`-index på ett kompatibelt sätt.

### Step 2: Add Data

I detta projekt genereras frågor primärt via `lib/core/services/question_generator_service.dart`.

Typiskt arbetssätt:
- Lägg till/justera logik för nya svårighetsgraden i generatorn.
- Uppdatera regler i `lib/core/config/difficulty_config.dart` (t.ex. ranges/step-buckets).


### Steg 3: Uppdatera affärslogik

Öppna `lib/domain/services/adaptive_difficulty_service.dart` och justera logik för progression mellan befintliga svårighetsgrader (`easy`, `medium`, `hard`).

Obs: Denna logik används ofta från Riverpod-notifiers i `lib/core/providers/`.


### Steg 4: Uppdatera UI (vid behov)

Om du behöver visa en ny eller ändrad svårighetsgrad i UI, sök efter `DifficultyLevel` i `lib/presentation/` och uppdatera de ställen där svårighetens label/rendering sker.

---

## 3. Testing Phase


### Skriv/uppdatera tester

I detta repo ligger tester under `test/unit/...` och `test/widget/...`.

För en ändring i svårighetslogik är det vanligast att uppdatera/bryta ut tester i:
- `test/unit/logic/difficulty_config_*_test.dart`
- `test/unit/logic/adaptive_difficulty_test.dart`

### Run Tests

```bash
# Exempel: kör en relevant, liten testfil
flutter test test/unit/logic/adaptive_difficulty_test.dart

# Eller kolla alla tester
flutter test
```


**Förväntat:** Alla tester ska passera.

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

**Förväntat:** Alla tester passerar.

### 4.3 Manual Smoke Test

Starta appen på emulator och testa manuellt:

```bash
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync
```


**Test checklist:**
- [ ] Appen startar
- [ ] Alla svårighetsgrader fungerar
- [ ] Frågor genereras korrekt per nivå
- [ ] Achievements sparas offline

---

## 5. Commit & Push Phase

### Clean Git History

Se till att du bara har relevanta files:

```bash
git status

# Förväntat output (ungefär):

# modified:   lib/domain/enums/difficulty_level.dart
# modified:   lib/core/config/difficulty_config.dart
# modified:   lib/core/services/question_generator_service.dart
# modified:   lib/domain/services/adaptive_difficulty_service.dart
# modified:   test/unit/logic/...
```

### Commit

```bash
git add .

git commit -m "feat: uppdatera svårighetsgrader

- Justerat DifficultyLevel-enum och relaterad logik
- Uppdaterat frågor och tester för nya nivåer

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
version: 1.3.1+9  # Var 1.3.0+8 innan

# Commit
git commit -m "chore: bump version to 1.3.1"

# Build release APK
flutter build apk --release

# Upload to Play Store
# (google play console UI)
```

---


## Exempel-checklista för ny/ändrad svårighetsgrad

```markdown
- [x] Models updated (DifficultyLevel enum)
- [x] Questions/logic updated
- [x] Business logic updated (progression)
- [x] UI updated (if needed)
- [x] Unit tests written and passing
- [x] flutter analyze passing
- [x] Manual smoke test på emulator
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
1. Skapa service (domain eller core beroende på beroenden):
  - Pure domain: `lib/domain/services/my_service.dart`
  - Flutter-aware: `lib/core/services/my_service.dart`
2. Exponera via provider i `lib/core/providers/` om den behövs i UI/state.
3. Om GetIt används: registrera i `lib/core/di/injection.dart`.

### Pattern 2: Add Persistent Data

För data som behöver sparas offline:

1. Create entity: `lib/domain/entities/my_entity.dart`
2. Use Hive: `@HiveType(typeId: N)` och `@HiveField(0)`
3. Create/uppdatera repository i `lib/data/repositories/`.
4. Kör codegen: `dart run build_runner build --delete-conflicting-outputs`

---

## Troubleshooting

### "Test fails with 'class not found'"
- **Orsak:** Import-sökväg fel
- **Lösning:** Kontrollera import i test-fil
  ```dart
  import 'package:siffersafari/domain/enums/difficulty_level.dart';
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
- **Code standards?** Se [CONTRIBUTING.md](CONTRIBUTING.md)
- **Folder structure?** Se [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
