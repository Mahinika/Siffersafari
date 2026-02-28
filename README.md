# Siffersafari

Ett pedagogiskt mattespel för barn (6-13+ år) som lär grundläggande matematik genom interaktiva övningar, quiz och progressionssystem.

## Status (2026-02-26)

Projektet är i ett fungerande MVP+-läge med:
- Quizflöde (hem → quiz → resultat)
- Multi-user profiler (skapa/välj aktiv användare)
- Årskurs per användare (Åk 1-9) som styr effektiv svårighet
- Progression (poäng, nivå, titel, medalj, streak)
- Föräldraläge (PIN, dashboard, rekommenderad övning, räknesätt per användare)
- Onboarding och widget-test

Senaste verifiering: 22 tester passerar, 0 fail.

## Funktioner

- **Adaptiv Svårighetsgrad**: Automatisk justering baserad på prestanda (70-80% framgångsfrekvens)
- **Spaced Repetition**: Vetenskapligt bevisad repetitionsalgoritm för långsiktig inlärning
- **Ålders-/Årskursanpassat Innehåll**: Tre åldersgrupper och stöd för Åk 1-9
- **Föräldra/Lärardashboard**: Detaljerad analys och framstegsvisualisering
- **Lokal datalagring (Hive)**: Kärnflödet använder lokal persistens
- **Temabaserad Design**: Engagerande teman (rymd, djungel)
- **Belöningssystem**: Stjärnor, medaljer, streaks för motivation

## Känd scope just nu

- Offline-funktionalitet är implementerad via lokal lagring men ej fullständigt validerad i testplan.
- Tillgänglighet, integrationstest, prestandaoptimering och produktionsdeploy återstår.

## Teknisk Stack

- **Framework**: Flutter 3.x
- **Språk**: Dart 3.x
- **State Management**: Riverpod
- **Lokal Databas**: Hive
- **Ljud**: audioplayers, just_audio
- **Animationer**: flutter_animate, Lottie

## Arkitektur

Projektet följer Clean Architecture-principer:

```
lib/
├── domain/          # Business logic, entiteter
├── data/            # Datakällor, repositories
├── presentation/    # UI, skärmar, widgets
└── core/            # Delad funktionalitet, services
```

Dokumentation (med Mermaid-diagram):
- `docs/ARCHITECTURE.md`
- `docs/MERMAID_GUIDE.md`

## Installation (Utveckling)

```bash
# Installera dependencies
flutter pub get

# Generera kod (Hive adapters, Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# Kör appen
flutter run
```

## Testning

```bash
# Enhetstester
flutter test

# Enhetstester med coverage
flutter test --coverage

# Analysera kod
flutter analyze
```

## Licens

Privat projekt - Alla rättigheter förbehållna.
