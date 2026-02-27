import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_game_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MVP smoke: create user and open quiz', (tester) async {
    await app.main();

    // App startup does async init (Hive + DI).
    await tester.pumpAndSettle(const Duration(seconds: 3));

    Future<void> ensureHomeVisible() async {
      final operationLabels = <String>[
        'Addition',
        'Subtraktion',
        'Multiplikation',
        'Division',
      ];

      bool hasOperationCards() {
        for (final label in operationLabels) {
          if (find.text(label).evaluate().isNotEmpty) return true;
        }
        return false;
      }

      for (var attempt = 0; attempt < 3; attempt++) {
        // Onboarding can block the UI.
        final onboardingTitle = find.text('Kom igång');
        if (onboardingTitle.evaluate().isNotEmpty) {
          final skipButton = find.text('Hoppa över');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            if (hasOperationCards()) return;
          }
        }

        // If we're in Settings, go back.
        if (find.text('Inställningar').evaluate().isNotEmpty) {
          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            if (hasOperationCards()) return;
          }
        }

        // If we're in Quiz, close it.
        if (find.textContaining('Fråga ').evaluate().isNotEmpty) {
          final close = find.byIcon(Icons.close);
          if (close.evaluate().isNotEmpty) {
            await tester.tap(close);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            if (hasOperationCards()) return;
          }
        }

        // If we're in Results, go back to start.
        final backToStart = find.text('Tillbaka till Start');
        if (backToStart.evaluate().isNotEmpty) {
          await tester.tap(backToStart);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          if (hasOperationCards()) return;
        }

        await tester.pumpAndSettle(const Duration(seconds: 1));
        if (hasOperationCards()) return;
      }
    }

    await ensureHomeVisible();

    // Fresh install path: create a user if none exists.
    final createUserHomeButton =
        find.widgetWithText(ElevatedButton, 'Skapa användare');
    if (createUserHomeButton.evaluate().isNotEmpty) {
      await tester.tap(createUserHomeButton);
      await tester.pumpAndSettle();
      // Create user dialog.
      expect(find.text('Skapa användare'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'Test');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skapa'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Onboarding can be pushed via post-frame callback after returning to Home.
    await ensureHomeVisible();

    // Start a quiz by tapping the first available operation card.
    final operationLabels = <String>[
      'Addition',
      'Subtraktion',
      'Multiplikation',
      'Division',
    ];

    Finder? chosenOperation;
    for (final label in operationLabels) {
      final candidate = find.text(label);
      if (candidate.evaluate().isNotEmpty) {
        chosenOperation = candidate;
        break;
      }
    }

    if (chosenOperation == null) {
      final visibleTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      fail(
        'No operation cards found on Home. Visible Text widgets: '
        '${visibleTexts.take(80).toList()}',
      );
    }

    await tester.tap(chosenOperation!);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Quiz screen should show a question title.
    expect(find.textContaining('Fråga '), findsOneWidget);

    // Close the quiz and return.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Ensure we're back on home (operation cards visible).
    Finder? anyOperation;
    for (final label in operationLabels) {
      final candidate = find.text(label);
      if (candidate.evaluate().isNotEmpty) {
        anyOperation = candidate;
        break;
      }
    }
    expect(anyOperation, isNotNull);
  });
}
