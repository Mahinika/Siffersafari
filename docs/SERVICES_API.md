# Services API (As-Is)

Detta dokument beskriver de centrala tjansterna i aktuell implementation (uppdaterad 2026-03-11).

## Oversikt

Services finns i tva lager:
- `lib/core/services/`: appnara/tekniska tjanster
- `lib/domain/services/`: Flutter-fria domantjanster

## Core services

### QuestionGeneratorService
Fil: `lib/core/services/question_generator_service.dart`

Ansvar:
- generera fragor per age group, grade, operation och difficulty/step
- hantera mix-fragor och curriculum-gates
- stod for word problems och missing-number varianter

Anvands av:
- `QuizNotifier` (start + nasta fraga)

### AudioService
Fil: `lib/core/services/audio_service.dart`

Ansvar:
- spela click/correct/wrong/celebration/music
- respektera profilernas sound/music settings

Anvands av:
- quizflow, results, home

### AchievementService
Fil: `lib/core/services/achievement_service.dart`

Ansvar:
- evaluera session + userprogress
- returnera upplasta achievements och bonus

Anvands av:
- `UserNotifier.applyQuizResult(...)`

### QuestProgressionService
Fil: `lib/core/services/quest_progression_service.dart`

Ansvar:
- bygga quest-path utifran grade/age
- ge current status och next quest
- filtrera path pa tillatna operationer

Anvands av:
- `UserNotifier`
- story-providerlagret

### StoryProgressionService
Fil: `lib/core/services/story_progression_service.dart`

Ansvar:
- mappa quest-status till UI-fardig storymodell
- satta node states (completed/current/upcoming)
- skapa chapter/landmark metadata

Anvands av:
- `storyProgressProvider`

### AppUpdateService
Fil: `lib/core/services/app_update_service.dart`

Ansvar:
- hamta senaste release via GitHub API
- jamfora installerad version med release-tag
- starta OTA-installation pa Android via `ota_update`

Anvands av:
- `ParentDashboardScreen`

## Domain services

### AdaptiveDifficultyService
Fil: `lib/domain/services/adaptive_difficulty_service.dart`

Ansvar:
- foresla nasta `difficultyStep` (inte bara easy/medium/hard)
- hybridmodell med micro/macro-signal + cooldown

Anvands av:
- `QuizNotifier.submitAnswer(...)`

### FeedbackService
Fil: `lib/domain/services/feedback_service.dart`

Ansvar:
- skapa `FeedbackResult` efter varje svar
- inkludera poang/snabbbonus/streak och alderanpassad text

Anvands av:
- `QuizNotifier.submitAnswer(...)`
- `FeedbackDialog`

### ParentPinService
Fil: `lib/domain/services/parent_pin_service.dart`

Ansvar:
- lagra PIN som BCrypt-hash
- verifiera PIN med lockout efter upprepade fel
- hantera security-question recovery

Anvands av:
- `ParentPinScreen`
- `PinRecoveryScreen`

### DataExportService
Fil: `lib/domain/services/data_export_service.dart`

Ansvar:
- exportera profildata/metadata till JSON-filer
- lista och radera exporterade filer

Anvands av:
- `ParentDashboardScreen`

### SpacedRepetitionService
Fil: `lib/domain/services/spaced_repetition_service.dart`

Ansvar:
- repetitionsintervall och due-berakning

Anvands av:
- `QuizNotifier.startSession(...)`
- `QuizNotifier.startCustomSession(...)`
- `QuizNotifier.submitAnswer(...)`

## Repository-kontrakt

### LocalStorageRepository
Fil: `lib/data/repositories/local_storage_repository.dart`

Ansvar:
- CRUD for `UserProgress`
- quizhistorik (in-progress + complete)
- settings helpers (active user, onboarding, quest state, operation filters)
- defensiv validering/rensning av korrupt sessiondata

## DI och providers

- DI: `lib/core/di/injection.dart`
- Providers: `lib/core/providers/*.dart`

Notera:
- Providers konsumerar services/repository via Riverpod.
- DI registrerar singleton/lazy-singleton for globala tjanster.
