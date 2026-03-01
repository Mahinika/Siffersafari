# Implementeringsstatus - 2026-03-01

## Översikt
Projektet är i ett fungerande MVP+-läge med kärnflöde, progression, föräldraläge, onboarding, widget-test och stabil lokal persistens.

---

## ✅ Verifierat klart (matchar TODO)

### Fas 1: Grundläggande arkitektur
- Clean Architecture-struktur i `lib/core`, `lib/data`, `lib/domain`, `lib/presentation`
- `pubspec.yaml` med nödvändiga dependencies
- Datamodeller: `Question`, `UserProgress`, `QuizSession`
- Enums: `AgeGroup`, `OperationType`, `DifficultyLevel`, `AppTheme`, `MasteryLevel`
- `DifficultyConfig` med ålders-/årskursstyrd svårighet
- `LocalStorageRepository` för Hive-boxar
- DI via GetIt i `lib/core/di/injection.dart`
- Konstanter + färgpalett i `lib/core/constants/app_constants.dart`
- Asset-mappar + README för ljud/bilder/animationer

### Fas 2: Kärn-lärsystem
- `QuestionGeneratorService`
- `AudioService`
- `AdaptiveDifficultyService`
- `SpacedRepetitionService`
- `FeedbackService`
- Enhetstester för question/adaptive/spaced repetition

### Fas 3: UI/UX & skärmar
- `HomeScreen`, `QuizScreen`, `ResultsScreen`, `SettingsScreen`
- “Öva mer” startar nytt quiz med samma operation och effektiv svårighet (inkl. årskurs)
- Återanvändbara widgets (`QuestionCard`, `AnswerButton`, `FeedbackDialog`, `ProgressIndicatorBar`, `StarRating`)
- Quiz får “spel-lager”: HUD (värld + ⚡/🔥), uppdragstext och korta micro-meddelanden vid milstolpar
- Riverpod providers för quiz, user, difficulty och parent settings
- Navigering mellan vyer och stabilt quiz→resultat-flöde
- Persistens av användardata och quizhistorik efter omstart

### Miljö & build
- Flutter SDK installerad och verifierad
- Körbar på emulator
- Hive TypeAdapters genererade/registrerade

### Fas 4: Progression & belöningar
- Nivåsystem (nivå + titel + progress)
- Belöningssystem (poäng, medaljindikator, svit/streak, snabbbonus ⚡)
- Ljud i flödet (rätt/fel/celebration)
- Achievement-system
- “Nästa mål”-visning på hemvyn

### Fas 4b: Inställningar (MVP)
- Minimal inställningsvy för ljud/musik
- Ljudinställningar synkas mot aktiv användare och sparas i Hive
- Årskurs (Åk 1–9) per användare styr effektiv svårighet

### Fas 5: Föräldra-/lärardashboard
- PIN-kod för föräldraläge med SHA-256 hashning
- Rate-limiting: 5 felaktiga försök → 5 min lockout
- Byt PIN inne i föräldraläge
- Dashboard med översikt + senaste quiz
- MVP-analys (svagaste områden + rekommenderad övning)
- Anpassning av aktiva räknesätt per användare

### Säkerhet & stabilitet
- Global felhantering (`FlutterError.onError`, `PlatformDispatcher.instance.onError`, `Isolate.current.addErrorListener`)
- Säker PIN-lagring med SHA-256 hash (aldrig klartext)
- `ParentPinService` med rate-limiting och lockout-mekanismer

### Fas 6/7 (delar)
- Onboarding/tutorial implementerad
- Widget-test finns

### Tekniska TODO (del)
- WAV-ljudfiler finns i `assets/sounds/`

---

## ✅ Nyligen färdigställt och stabiliserat (2026-03-01)
- **Global felhantering** i main.dart för proaktiv diagnostik och crashprevention
- **Säker PIN-lagring** med SHA-256 hash + rate-limiting (5 försök → 5 min lockout)
- `ParentPinService` skapad i domain/services med full testning
- Lekigare quiz-feedback: snabbbonus ⚡, svit 🔥 och mjuk “ny svit på gång” när sviten bryts
- **M2: Textuppgifter (word problems)** i befintligt quizflöde (per barn: switch “Textuppgifter”, Åk 1–3 för +/−, och konservativt Åk 3 för ×/÷)
- **M2.5: Saknat tal** i befintligt quizflöde (per barn: switch “Saknat tal”, +/− för Åk 2–3, och prioritet över textuppgifter om båda är på)
- Demo-seed borttaget (ingen automatisk demo-användare skapas)
- Multi-user stöd (skapa/välj aktiv användare)
- Aktiv användare persisteras (`active_user_id`)
- Legacy-städning vid uppstart:
  - Rensar tidigare "Demo Användare" profiler
  - Rensar relaterad quizhistorik
  - Rensar relaterade per-user settings
- Pixel_6-flöde/scripthantering finns i `scripts/`

---

## 📊 Teststatus
- Senaste verifiering: **52 tester passerar, 0 fail**
- Tester inkluderar:
  - Enhetstester för kärnlogik (services, difficulty, repetition, progression)
  - Widget-tester för centrala appflöden
  - Integration smoke-test

---

## 🟡 Återstår (nästa fokus)
- Prestanda-optimering
- User testing med målgrupp
- Tema-bilder/visuella assets (rymd/djungel)
- Produktionsdeploy: Android signing + Play Store metadata + intern/beta

---

## Kommentar
Detta dokument är uppdaterat per 2026-03-01 efter att quizet fått mer “spel-känsla” (HUD/uppdrag/micro-feedback), samt efter införandet av textuppgifter och "saknat tal" i quizflödet.
