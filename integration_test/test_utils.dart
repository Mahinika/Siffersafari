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
  await tester.pumpAndSettle(duration);
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
  Duration after = const Duration(milliseconds: 900),
  List<String>? errors,
}) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 200));

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

    // If the finder targets a composite (e.g. ElevatedButton/DropdownButton),
    // tap on an internal render box that participates in hit testing.
    find.descendant(of: finder, matching: find.byType(InkResponse)),
    find.descendant(of: finder, matching: find.byType(InkWell)),
    find.descendant(of: finder, matching: find.byType(GestureDetector)),

    // Last resort.
    finder,
  ];

  for (final candidate in candidates) {
    bool hasMatch;
    try {
      hasMatch = candidate.evaluate().isNotEmpty;
    } catch (_) {
      continue;
    }
    if (!hasMatch) continue;

    final target = candidate.first;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    try {
      await tester.tap(target);
      await tester.pumpAndSettle(after);
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
  Duration after = const Duration(milliseconds: 900),
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
  Duration after = const Duration(seconds: 1),
}) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await tester.pumpAndSettle(after);
    return;
  }

  await tester.pageBack();
  await tester.pumpAndSettle(after);
}
