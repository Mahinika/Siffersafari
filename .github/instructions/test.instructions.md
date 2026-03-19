---
description: "Testkonventioner för test/ – widget-tester, unit-tester, setup-mönster"
applyTo: "test/**"
---

# Testkonventioner (Siffersafari)

## Struktur

```
test/
├── test_utils.dart          ← allt delat: mocks, fakes, helpers, setupWidgetTestDependencies()
├── unit/
│   ├── logic/               ← rena logiktester utan Flutter-beroenden
│   └── services/            ← domäntjänstertester
└── widget/                  ← full widget-träd via MathGameApp + ProviderScope
```

## Widget-test setup (standard)

Alltid detta mönster i `widget/`-tester:

```dart
late InMemoryLocalStorageRepository repository;

setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

setUp(() async {
  repository = await setupWidgetTestDependencies();
});
```

`setupWidgetTestDependencies()` ligger i `test/test_utils.dart` och gör:
1. `getIt.reset()`
2. Registrerar `InMemoryLocalStorageRepository` (Hive-fri)
3. Registrerar `MockAudioService` med stubbade metoder
4. Registrerar `FakeQuestionGeneratorService` (deterministisk, returnerar alltid 6×7=42)
5. Anropar `initializeDependencies(initializeHive: false)`

**Lägg inte till extra `getIt.registerSingleton`-anrop utanför `setupWidgetTestDependencies` om det inte är absolut nödvändigt.**

## ScreenUtil – ingen separat init krävs

`ScreenUtil.init()` sker via `MathGameApp`. Widget-tester som pumpar `MathGameApp` behöver **inte** anropa `ScreenUtil.init()` i setUp.

Om du testar en isolerad widget (inte via `MathGameApp`), wrappa med:

```dart
await tester.pumpWidget(
  ScreenUtilInit(
    designSize: const Size(375, 812),
    child: MaterialApp(home: MyWidget()),
  ),
);
```

## Device-storlek i widget-tester

Sätt alltid en fast skärmstorlek för att undvika flöjlighet med layout-breakpoints:

```dart
tester.view.devicePixelRatio = 1.0;
tester.view.physicalSize = const Size(375, 812);
addTearDown(() {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
});
```

## Hjälpfunktioner (test_utils.dart)

| Funktion | Användning |
|---|---|
| `pumpFor(tester, duration)` | Pumpa animationer i 50 ms-steg |
| `pumpUntilFound(tester, finder)` | Vänta på att en widget dyker upp (max 4 s) |
| `skipOnboardingIfPresent(tester)` | Hoppa över onboarding om den visas |

Undvik `tester.pump(const Duration(seconds: 5))` – använd `pumpFor` eller `pumpUntilFound` i stället.

## Mocking och stubs

- Mocktail används för `AudioService` (alla metoder stubbas till `async {}`).
- Använd `InMemoryLocalStorageRepository` istället för att mocka `LocalStorageRepository` – det är renare och täcker verklig lagringslogik.
- Kör `await repository.clearAllData()` i testets `setUp` eller i testets inledning om du behöver rent state.

## Testnamn

```dart
test('[Unit] ServiceNamn – vad som testas', () { ... });
testWidgets('[Widget] SkärmNamn – flöde som testas', (tester) async { ... });
```

## Unit-tester

- Ingen Flutter-bindning, ingen `TestWidgetsFlutterBinding.ensureInitialized`.
- Skapa tjänsten direkt i `setUp`: `service = MyService();`.
- Testa beteende, inte implementation – inga internals som `_field`.

## Vanliga fallgropar

- **ScreenUtil-kraschar**: uppstår om en widget som använder `.w`/`.h` pumpas utan `MathGameApp` eller `ScreenUtilInit`. Lägg till wrappern.
- **`getIt` är inte resetad**: om ett test registrerar något utan att anropa `getIt.reset()` smittar det nästa test. `setupWidgetTestDependencies()` hanterar detta.
- **Onboarding blockerar flödet**: kalla `skipOnboardingIfPresent` eller sätt `onboarding_done_<userId>` = true i repositoryt innan pumpning.
- **Animationer avslutas inte**: använd `pumpFor(tester, AppConstants.mediumAnimationDuration + const Duration(milliseconds: 150))` efter att ha tryckt på knappar.
- **Stale quiz-state**: anropa `repository.clearAllData()` i testets inledning om ett tidigare test kan ha lämnat kvar data.
