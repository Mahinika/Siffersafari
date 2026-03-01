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

### Fas 7: Prestanda-optimering (påbörjad)
- Prestanda-baseline etablerad (Pixel_6, 2026-03-01)
- Fas 1 implementerad: Async Hive init med FutureBuilder + loading screen
- **Status**: Blandade resultat
  - ✅ Frame skips: -26% (253 → 187)
  - ❌ Cold start: +47% (3.5s → 5.1s)
  - ❌ Memory: +68% (140 MB → 235 MB)
  - ❌ APK: +29% (136 MB → 175 MB)
- **Analys**: Async-pattern gav inte förväntad förbättring; memory/APK-ökning troligen pga M4a/M5a-tillägg
- **Nästa steg**: Överväg revertering och fokusera på MP3/asset-optimering först
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
- **M4 (light, ingen ny UI):** statistik + sannolikhet i `Mix` för Åk 4–6 (typvärde/median/medelvärde/variationsbredd/chans i %/skillnad i chans) + enkel kombinatorik (kombinationer)
- **M4 (full, delsteg):** visualiserad statistik i texttabell med tolkning i `Mix` för Åk 4–6
- **M4 (full, alla delsteg): Slutfört** ✅
- **M5a (utan ny UI): Slutfört** ✅ — negativa tal, procent, potenser, prioriteringsregler för Åk 7–9
- **M5b delstep 1 (Linjära funktioner): Slutfört** ✅ — textbaserad y=mx+b med koordinatvisualisering för Åk 7–9, trigger vid step 8+ (10% i Mix)
- **M5b delstep 2 (Geometriska transformationer): Slutfört** ✅ — spegling/rotation/translation i koordinatsystem för Åk 7–9, trigger vid step 8+ (10% i Mix)
- **M5b delstep 3 (Avancerad statistik): Slutfört** ✅ — outliers/distributioner/korrelationer för Åk 7–9, trigger vid step 8+ (10% i Mix)
- **M4a (Tid - klockan): Slutfört** ✅ — tidfrågor för Åk 1–3 i Mix (hel/halv timme Åk 1, + kvart Åk 2, alla minuter + tidsintervall Åk 3), trigger 10% vid roll 0.75–0.85
- **QA:** deterministiskt audit-test som kontrollerar Mix-fördelningen för M4 specialfrågor per Åk 4–6 och step-bucket
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
- Senaste verifiering: **59 tester passerar, 0 fail** (M4a + M5b delstep 1-3, +8 nya tester totalt)
- Tester inkluderar:
  - Enhetstester för kärnlogik (services, difficulty, repetition, progression)
  - Widget-tester för centrala appflöden
  - Integration smoke-test
  - M4 diagram/sannolikhet/geometri-distribution audit tests
  - M5a procent/potenser/prioriteringsregler tests
  - M5b 1-3 tests (linjär funktion, geometrisk transformation, avancerad statistik)
  - M4a tid-frågor tests (klockan för Åk 1–3)

---

## 🟡 Återstår (nästa fokus)
- Prestanda-optimering
- User testing med målgrupp
- Tema-bilder/visuella assets (rymd/djungel)
- Produktionsdeploy: Android signing + Play Store metadata + intern/beta
- **Läroplan M5b: Åk 7–9**
  - ✅ Delstep 1: Linjära funktioner (textruta med koordinat-lista)
  - ✅ Delstep 2: Geometriska transformationer (spegling/rotation/translation)
  - ✅ Delstep 3: Avancerad statistik-visualisering (outliers, distributioner, korrelationer)

**M5b nu helt slutförd!** 🎉

---

## Kommentar
Detta dokument är uppdaterat per 2026-03-01 efter att **M4 full, M5a och M5b (alla delsteps) slutförts**:
- M4 full: statistik-tabell + diagram + sannolikhets-visualisering + geometri/mätning i Mix för Åk 4–6 ✅
- M5a: negativa tal + procent + potenser + prioriteringsregler i Mix för Åk 7–9 ✅
- M5b delstep 1: linjära funktioner med textruta-visualisering i Mix för Åk 7–9 (step 8+) ✅
- M5b delstep 2: geometriska transformationer (spegling/rotation/translation) i Mix för Åk 7–9 (step 8+) ✅
- M5b delstep 3: avancerad statistik (outliers, distributioner, korrelationer) i Mix för Åk 7–9 (step 8+) ✅
