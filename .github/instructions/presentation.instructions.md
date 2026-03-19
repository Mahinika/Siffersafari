---
description: "Konventioner för lib/presentation/ – skärmar, dialoger, widgets"
applyTo: "lib/presentation/**"
---

# Presentation-konventioner (Siffersafari)

## Klass-hierarki

```
Screen      → ConsumerStatefulWidget  (har navigering, livcykellogik, ref.watch)
Dialog      → ConsumerStatefulWidget  (showXxxDialog-funktion som wrapper; private _XxxDialog-klass)
Widget      → StatelessWidget         (ingen navigering; tar alla beroenden som parametrar)
```

- Screens ärver `ConsumerStatefulWidget` + `ConsumerState<T>`.
- Dialoger lanseras via en top-level `showXxxDialog({required BuildContext context, required WidgetRef ref})` och implementeras som en private `_XxxDialog extends ConsumerStatefulWidget`.
- Rena widgets är `StatelessWidget` – de tar **alla** beroenden som konstruktorparametrar, kopplar inte mot providers internt.

## Riverpod-mönster

- `ref.watch(provider)` i `build()` – aldrig i `initState` eller callbacks.
- `ref.read(provider.notifier)` i event-handlers och `initState`.
- Undvik `ref.listen` utanför `build()` – sätt upp i `build()` om du behöver sidoeffekter.
- Screen-state som beror på aktiv användare (`user.userId`) skyddas mot dubbla callbacks med en sentinelvariabel, t.ex.:

```dart
if (user != null && _loadedFor != user.userId) {
  _loadedFor = user.userId;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(someProvider.notifier).load(user.userId);
  });
}
```

## ScreenUtil

- Används **bara** i `lib/presentation/` (inte i domain/data/core).
- Geometri: `.w` och `.h` för mått som ska skalas, **inte** `.r` (undvik).
- Hämta baslinjen `AppConstants.defaultPadding` etc. och applicera `.w` i widget-trädet.
- Kör **aldrig** `ScreenUtil.init()` inuti widgets – det sker i `MathGameApp`.

## Layout – responsivitet

Använd `AdaptiveLayoutInfo.fromConstraints(constraints)` via `LayoutBuilder`, inte hårdkodade breakpoints:

```dart
LayoutBuilder(builder: (context, constraints) {
  final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
  final cols = layout.gridColumns(compact: 2, medium: 3, expanded: 4);
  ...
})
```

Breakpoints: compact < 600, medium ≥ 600, expanded ≥ 840 (logiska pixlar).

## Navigering

Använd `context.pushSmooth(...)` och `context.pushReplacementSmooth(...)` från `core/utils/page_transitions.dart` – **inte** `Navigator.push` direkt.

## Tema och färger

- Hämta alltid temat via `ref.watch(appThemeConfigProvider)` för app-specifika tokens.
- Grundläggande `ColorScheme`-värden via `Theme.of(context).colorScheme`.
- Alfavärden för transparens: använd `AppOpacities.*`-konstanterna, inte hårdkodade doubles.

## ThemedBackgroundScaffold

Alla skärmar som visar temat (bakgrundsbild, gradient) ska wrappas i `ThemedBackgroundScaffold` – **inte** ett vanligt `Scaffold`. Undantag: dialoger och overlay-skärmar utan bakgrundsbild.

## Semantik

- Lägg `Semantics(label: '...')` på interaktiva eller informationsbärande widgets som saknar tydlig accessibilitetslabel.
- `ExcludeSemantics` används för dekorativa element.

## WidgetsBinding.addPostFrameCallback

Används för att skjuta upp sidoeffekter (navigation, provider-anrop) till efter build. Kolla alltid `if (!mounted) return;` direkt i callbacket.

## Dispose

`TextEditingController`, `AnimationController` etc. ska alltid ha en matchande `dispose()`.
