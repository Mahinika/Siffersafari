import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _describe(FinderBase finder) {
  try {
    return finder.describeMatch(Plurality.one);
  } catch (_) {
    return finder.toString();
  }
}

Future<void> settle(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 800),
]) async {
  // In integration tests the app can have continuous animations/tickers.
  // Avoid pumpAndSettle() hanging forever by pumping in small steps up to a
  // maximum total duration.
  const step = Duration(milliseconds: 50);
  final steps =
      (duration.inMilliseconds / step.inMilliseconds).ceil().clamp(1, 400);
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) return;
  }
}

List<String> visibleTexts(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? w.textSpan?.toPlainText())
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  texts.sort();
  return texts;
}

/// Tries to tap something hittable.
///
/// This is defensive against Finders that target a leaf (Text/Icon) inside a
/// tappable widget, or composites like DropdownButton that need a descendant
/// render object.
Future<bool> tryTap(
  WidgetTester tester,
  Finder finder, {
  Duration after = const Duration(milliseconds: 450),
  List<String>? errors,
}) async {
  await settle(tester, const Duration(milliseconds: 200));

  final candidates = <Finder>[
    // If the finder targets a leaf (Text/Icon), climb to common tappables.
    find.ancestor(of: finder, matching: find.byType(IconButton)),
    find.ancestor(of: finder, matching: find.byType(ElevatedButton)),
    find.ancestor(of: finder, matching: find.byType(FilledButton)),
    find.ancestor(of: finder, matching: find.byType(OutlinedButton)),
    find.ancestor(of: finder, matching: find.byType(TextButton)),
    find.ancestor(of: finder, matching: find.byType(ListTile)),
    find.ancestor(of: finder, matching: find.byType(InkWell)),
    find.ancestor(of: finder, matching: find.byType(InkResponse)),
    find.ancestor(of: finder, matching: find.byType(GestureDetector)),

    // If the finder already points at a tappable/composite widget, prefer
    // scrolling and tapping that before drilling into internal render objects.
    finder,

    // If the finder targets a composite (e.g. ElevatedButton/DropdownButton),
    // tap on an internal render box that participates in hit testing.
    find.descendant(of: finder, matching: find.byType(InkResponse)),
    find.descendant(of: finder, matching: find.byType(InkWell)),
    find.descendant(of: finder, matching: find.byType(GestureDetector)),
  ];

  for (final candidate in candidates) {
    bool hasMatch;
    try {
      hasMatch = candidate.evaluate().isNotEmpty;
    } catch (_) {
      continue;
    }
    if (!hasMatch) continue;

    final hitTestableCandidate = candidate.hitTestable();
    var target = hitTestableCandidate.evaluate().isNotEmpty
        ? hitTestableCandidate.first
        : candidate.first;
    await tester.ensureVisible(target);
    await settle(tester, const Duration(milliseconds: 200));

    final postScrollHitTestable = candidate.hitTestable();
    if (postScrollHitTestable.evaluate().isNotEmpty) {
      target = postScrollHitTestable.first;
    }

    try {
      await tester.tap(target);
      await settle(tester, after);
      return true;
    } catch (e) {
      errors?.add('${_describe(candidate)}: $e');
    }
  }

  return false;
}

Future<void> tap(
  WidgetTester tester,
  Finder finder, {
  Duration after = const Duration(milliseconds: 450),
}) async {
  final errors = <String>[];
  final ok = await tryTap(
    tester,
    finder,
    after: after,
    errors: errors,
  );
  if (ok) return;

  fail(
    'Tried to tap a widget, but no tappable RenderBox was found. '
    'Finder: ${_describe(finder)}. Errors: $errors. '
    'Visible texts: ${visibleTexts(tester).take(80).toList()}',
  );
}

Future<void> backOnce(
  WidgetTester tester, {
  Duration after = const Duration(milliseconds: 450),
}) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester, after);
    return;
  }

  final closeButton = find.byType(CloseButton);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.first);
    await settle(tester, after);
    return;
  }

  final arrowBack = find.widgetWithIcon(IconButton, Icons.arrow_back);
  if (arrowBack.evaluate().isNotEmpty) {
    await tester.tap(arrowBack.first);
    await settle(tester, after);
    return;
  }

  final tooltipBack = find.byTooltip('Back');
  if (tooltipBack.evaluate().isNotEmpty) {
    await tester.tap(tooltipBack.first);
    await settle(tester, after);
    return;
  }

  final tooltipTillbaka = find.byTooltip('Tillbaka');
  if (tooltipTillbaka.evaluate().isNotEmpty) {
    await tester.tap(tooltipTillbaka.first);
    await settle(tester, after);
    return;
  }

  fail(
    'No back/close button found. Visible texts: '
    '${visibleTexts(tester).take(80).toList()}',
  );
}

Future<void> waitFor(
  WidgetTester tester,
  String label,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 120),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await tester.pump(step);
  }

  fail(
    'Timed out waiting for: $label. Visible texts: '
    '${visibleTexts(tester).take(120).toList()}',
  );
}

Future<void> waitForText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 120),
}) async {
  await waitFor(
    tester,
    'text="$text"',
    () => find.text(text).evaluate().isNotEmpty,
    timeout: timeout,
    step: step,
  );
}
