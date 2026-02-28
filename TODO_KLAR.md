# TODO — KLARA PUNKTER

Genererad: 2026-02-27

Denna fil samlar alla **klara** checkboxar från TODO.md och FÖRBÄTTRINGAR.md.

---

## Från TODO.md

### Fas 1: Grundläggande Arkitektur
- [x] Projektstruktur skapad (Clean Architecture)
- [x] pubspec.yaml konfigurerad med alla dependencies
- [x] Datamodeller definierade (Question, UserProgress, QuizSession)
- [x] Enums skapade (AgeGroup, OperationType, DifficultyLevel, etc.)
- [x] DifficultyConfig med åldersanpassade talområden
- [x] LocalStorageRepository för Hive
- [x] Dependency Injection setup
- [x] Konstanter och färgpalett
- [x] Asset-mappar och dokumentation

### Fas 2: Kärn-Lärsystem
- [x] QuestionGeneratorService - Genererar matematikfrågor
- [x] AudioService - Ljudeffekter och musik
- [x] AdaptiveDifficultyService - Justerar svårighetsgrad baserat på prestanda
- [x] SpacedRepetitionService - Schemaläggning av repetition
- [x] FeedbackService - Genererar åldersanpassad feedback
- [x] Enhetstester för QuestionGenerator, AdaptiveDifficulty, SpacedRepetition

### Fas 3: UI/UX & Skärmar
- [x] QuizScreen - Interaktiv träningsskärm med frågor och svar
- [x] ResultsScreen - Visar resultat med stjärnbetyg
- [x] "Öva mer" startar nytt quiz med samma inställningar (inkl. ev. årskurs)
- [x] HomeScreen - Uppdaterad med användarstats och operationsval
- [x] Återanvändbara widgets (QuestionCard, AnswerButton, FeedbackDialog, etc.)
- [x] State Management (Riverpod providers: quiz, user, difficulty)
- [x] Navigering mellan skärmar
- [x] Quiz → Resultat-flöde fixat (ingen fastnar i "Ingen aktiv quiz-session")
- [x] Persistens verifierad (poäng/streak/quiz sparas efter omstart)

### Miljö & Build
- [x] Flutter SDK installerad och projektet körs på emulator
- [x] Hive TypeAdapters genererade och registrerade

### Fas 4: Progression & Belöningar
- [x] Nivåsystem med hierarki (nivå + titel)
- [x] Belöningssystem (poäng, stjärnor, medaljer, streaks)
- [x] Ljudintegration i flödet (correct/wrong/celebration)
- [x] Achievement-system
- [x] Visa "nästa mål" (t.ex. poäng kvar till nästa medalj/nivå)

### Fas 4b: Inställningar (MVP)
- [x] Minimal inställningsvy: ljud (on/off) och musik (on/off)
- [x] Synka audio-inställningar med aktiv användare (sparas i Hive)
- [x] Årskurs (Åk 1–9) per användarprofil som styr svårighet

### Fas 5: Föräldra/Lärardashboard
- [x] PIN-kod autentisering (föräldraläge)
- [x] Byt PIN (inne i föräldraläge)
- [x] Dashboard med grundstatistik (översikt + senaste quiz)
- [x] Detaljerad analys (MVP: svagaste områden + rekommenderad övning)
- [x] Anpassningsinställningar (MVP: slå av/på räknesätt per användare)
- [x] Robust läsning av quiz-historik (fix för Map-cast crash i föräldraläge)

### Fas 6: Polish & Extra
- [x] Offline-funktionalitet validering (2026-02-26)
- [x] Tillgänglighet (MVP: Semantics/labels för skärmläsare, progress/ratings labels, feedback announce)
- [x] Onboarding och tutorial
- [x] Animationer (Lottie-integration)

### Fas 7: Testing & Optimering
- [x] Utökade enhetstester
- [x] Widget-tester
- [x] Integration-tester (smoke)

### Fas 8: Produktionsdeploy
- [x] Bygga och installera release lokalt (emulator)

### Tekniska TODO
- [x] Lägg till riktiga ljudfiler i `assets/sounds/`
- [x] Lägg till Lottie-animationer i `assets/animations/`
- [x] Konfigurera CI/CD (GitHub Actions)
- [x] Lägg till global felhantering i `main.dart` (`FlutterError.onError` + `PlatformDispatcher.instance.onError` + `Isolate.current.addErrorListener`)
- [x] Härda föräldra-PIN: hashad lagring (SHA-256) + enkel rate-limit efter flera felaktiga försök (5 försök → 5 min lockout)

### Dokumentation TODO
- [x] API-dokumentation för services
- [x] Usage guide för parents/teachers
- [x] Screenshot guide för app stores
- [x] Privacy policy (draft)
- [x] Terms of service (draft)

---

## Från FÖRBÄTTRINGAR.md

### P0 — Grundflöden (kom igång + flyt)
- [x] Kartlägg top 3 flöden som ska vara snabbast
  - [x] Hem → Starta pass
  - [x] Pass klart → Öva på det svåraste
  - [x] Pass klart → Spela igen
- [x] Bestäm exakta val för årskurs (1–6) och räknesätt (default: Multiplikation)
- [x] Bestäm mål-alternativ: 5 / 10 (rekommenderas) / 20 / 30 frågor
- [x] Definiera vad som räknas som "dagens mål" (frågor besvarade i träningspass)
- [x] Spara onboarding-val i settings (årskurs, räknesätt, dagligt mål)
- [x] Lägg till onboarding-flöde (max 3 steg + start) med tydlig primärknapp
- [x] Hantera "Hoppa över": rimliga defaults sätts
- [x] Visa "Ditt mål idag: X frågor" på lämplig plats
- [x] Lägg till enkel progress: "n/X" för dagens mål
- [x] Definiera data som behövs i sammanfattningen: rätt/fel, tid, svåraste (max 3)
- [x] Skapa sammanfattningsskärm efter pass
- [x] Knapp 2 (sekundär): "Spela igen" (samma upplägg som nyss)
- [x] Länk/knapp: "Till hem"
- [x] Säkerställ att varje skärm har en tydlig primärknapp (och konsekvent placering)
- [x] Minimera val innan start (standardval + snabbt start-läge)
- [x] Säkerställ att navigation inte skapar extra "bekräfta"-steg i onödan
- [x] Gör knappar större och enklare att träffa där det behövs (lågstadie-händer)
- [x] Test: settings sparas/läses korrekt och onboarding visas bara första gången
- [x] Snabb QA på emulator

### P1 — Smartare feedback (svårast + rekommenderad nästa)
- [x] Visa "Svårast idag" (max 3) eller "Inget särskilt – riktigt bra!"
- [x] Copy/texter: barnvänliga men neutrala ("Bra jobbat!", "Bra kämpat!")
- [x] Lägg till rekommenderad nästa övning
  - [x] Enkelt urval: 2–3 svagaste tabeller/frågetyper baserat på fel och/eller långsam tid
  - [x] Mini-pass: 8–12 frågor, 70–80% fokus på svaga + 20–30% lätta
- [x] Knapp 1 (primär): "Öva på det svåraste (2 min)"
- [x] Test: rekommendation skapas även om passet har få frågor / inga tydliga svagheter

### P2 — Kvalitet & långsiktig hållbarhet
- [x] Lägg till/uppdatera enhetstester för nya settings och rekommendationslogik
- [x] Säkerställ att föräldraläge fortsatt fungerar utan extra krångel
- [x] QA: kör igenom flödena och räkna antal tryck
  - [x] Dokumentera tryckräkning (baseline)
  - [x] Kapning: Start → "Skapa användare" öppnar dialog direkt
  - [x] Kapning: Onboarding hoppar över årskurs om redan vald
  - [x] Kör igenom på emulator och uppdatera siffror (verifiera)

---

**Senast uppdaterad:** 2026-02-28 (efter implementering av global felhantering + säker PIN)
