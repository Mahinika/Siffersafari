# Siffersafari

Ett pedagogiskt mattespel för barn (6-13+ år) som lär grundläggande matematik genom interaktiva övningar, quiz och progressionssystem.

Fokus: **Android-only**, **offline-first**, flera barnprofiler.

## Status (2026-02-28)

Projektet är i ett fungerande MVP+-läge med:
- Quizflöde (hem → quiz → resultat)
- Multi-user profiler (skapa/välj aktiv användare)
- Profilval vid start när flera profiler finns
- Enkel profil-avatar (emoji) per barn
- Årskurs per användare (Åk 1-9) som styr effektiv svårighet
- Progression (poäng, nivå, titel, medalj, streak)
- Föräldraläge (PIN, dashboard, rekommenderad övning, räknesätt per användare)
	- PIN lagras som **SHA-256-hash** (inte klartext)
	- **Rate-limiting**: 5 felaktiga försök → 5 min lockout
- Onboarding och widget-test
- Global felhantering (för bättre diagnostik vid oväntade fel)

Senaste verifiering: 52 tester passerar, 0 fail.

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

### Rekommenderat (Android): Pixel_6-script för deterministisk install

Om du märker att emulatorn ibland kör “fel APK” (gamla ändringar), använd scriptet som alltid riktar mot **Pixel_6** och kan köra ett deterministiskt build+install-flöde:

```bash
# SYNC: bygg + installera exakt APK + starta om appen (säkrast när emulatorn måste matcha koden)
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync

# RUN: dev-läge med hot reload
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action run
```

Det finns även VS Code tasks som använder samma flöde.

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
