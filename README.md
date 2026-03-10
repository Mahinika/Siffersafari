# Siffersafari

<p align="center"><strong>Offline-first mattespel för barn 6-12 år.</strong><br>Adaptiv träning, flera barnprofiler och PIN-skyddat föräldraläge i en Android-app som går att installera direkt från GitHub Releases.</p>

<p align="center">
  <a href="https://github.com/Cognifox-Studio/Siffersafari/actions/workflows/flutter.yml"><img src="https://github.com/Cognifox-Studio/Siffersafari/actions/workflows/flutter.yml/badge.svg" alt="Flutter CI"></a>
  <a href="https://github.com/Cognifox-Studio/Siffersafari/actions/workflows/build.yml"><img src="https://github.com/Cognifox-Studio/Siffersafari/actions/workflows/build.yml/badge.svg" alt="Build and Release APK"></a>
  <a href="https://github.com/Cognifox-Studio/Siffersafari/releases"><img src="https://img.shields.io/github/v/release/Cognifox-Studio/Siffersafari?display_name=tag" alt="Latest release"></a>
</p>

<p align="center">
  <a href="https://github.com/Cognifox-Studio/Siffersafari/releases/latest/download/app-release.apk"><strong>Ladda ner senaste APK</strong></a>
  ·
  <a href="https://github.com/Cognifox-Studio/Siffersafari/releases"><strong>Se releases</strong></a>
  ·
  <a href="docs/README.md"><strong>Dokumentation</strong></a>
</p>

## Varför Siffersafari?

Siffersafari kombinerar lekfull matteövning med ett robust offline-flöde som fungerar utan konto, molnsync eller uppkoppling. Fokus ligger på att göra daglig träning enkel för barnet och överblickbar för förälder eller lärare.

Det här projektet passar särskilt bra när du vill ha:

- en Android-app som kan installeras direkt via APK
- adaptiv svårighetsgrad i stället för statiska uppgiftspaket
- flera barnprofiler på samma enhet
- lokalt sparad progression och PIN-skyddade vuxeninställningar

## Höjdpunkter

| Område | Det användaren märker |
| --- | --- |
| Adaptiv träning | Frågorna justeras efter prestation för att hålla nivån lagom utmanande |
| Årskursstyrning | Innehållet kan anpassas efter Åk 1-9 och valda räknesätt |
| Föräldraläge | Vuxna kan låsa upp dashboard, se statistik och styra innehåll via PIN |
| Offline-first | Kärnflödet fungerar utan internet och sparar data lokalt med Hive |
| Motivation | Poäng, streaks, medaljer och belöningar gör övningen mer engagerande |
| Teman | Djungel och rymd ger appen ett tydligt barnvänligt uttryck |

## Produktöversikt

- Quizflöde från hemskärm till resultatvy
- Flera barnprofiler med egen progression
- Rekommenderad övning och statistik i föräldradashboard
- PIN-skydd med BCrypt-hashning och begränsning av felaktiga försök
- Onboarding, widgettester och lokal release-byggning via GitHub Actions

## Installera APK

1. Gå till [Releases](https://github.com/Cognifox-Studio/Siffersafari/releases).
2. Ladda ner `app-release.apk` från senaste versionen.
3. Öppna filen på Android-enheten och installera.
4. Tillåt installation från okända appar för webbläsare eller filhanterare om Android frågar.

Direktlänk till senaste APK:

[https://github.com/Cognifox-Studio/Siffersafari/releases/latest/download/app-release.apk](https://github.com/Cognifox-Studio/Siffersafari/releases/latest/download/app-release.apk)

## Snabbstart för utveckling

För full setup: [docs/SETUP_ENVIRONMENT.md](docs/SETUP_ENVIRONMENT.md)

Snabbaste vägen igång:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

För deterministisk Android-körning i detta repo finns Pixel_6-scriptet:

```bash
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action sync
powershell -ExecutionPolicy Bypass -File scripts/flutter_pixel6.ps1 -Action run
```

## Kvalitet och release

- CI kör analyze och testsvit på kodändringar
- Release-workflow bygger signerad APK från `v*`-taggar
- Senaste lokala sanity check inför release: `flutter analyze`, `flutter test` och `flutter build apk --release`

Snabbkommandon lokalt:

```bash
flutter analyze
flutter test
flutter build apk --release
```

## Teknisk översikt

- Flutter + Dart 3
- Riverpod för state management
- Hive för lokal persistens
- audioplayers för ljud
- Rive för interaktiva karaktärsanimationer (Ville)
- Lottie för UI-effekter (konfetti, stjärnor, pulser)
- flutter_screenutil för responsiv skalning

Karaktärspipelinen är nu hybrid:

- Karaktärsrigg/specs under `assets/characters/ville/`
- UI-effekter under `assets/ui/lottie/`
- Rive-widget med triggers i quiz/home/results för `answer_correct`, `answer_wrong`, `user_tap`, `screen_change`

Projektet följer en tydlig lagerindelning:

```text
lib/
├── domain/
├── data/
├── presentation/
└── core/
```

Mer detaljer finns i:

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)
- [docs/KUNSKAPSNIVA_PER_AK.md](docs/KUNSKAPSNIVA_PER_AK.md)

## Dokumentation

Viktiga länkar:

- [docs/README.md](docs/README.md)
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)
- [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [docs/DEPLOY_ANDROID.md](docs/DEPLOY_ANDROID.md)

## Nuvarande scope

Redo idag:

- Android-fokuserad APK-distribution
- offline-first kärnflöde
- adaptiv quizlogik
- föräldraläge med återställningsflöde

Fortsatt utveckling:

- bredare integrationstestning
- mer tillgänglighetsarbete
- vidare prestandapolering och mer produktmedia för repo- och release-sidor

## Licens

Privat projekt. Alla rättigheter förbehållna.
