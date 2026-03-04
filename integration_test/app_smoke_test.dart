import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_game_app/main.dart' as app;

import 'test_utils.dart' as it;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integration (smoke): skapa användare vid behov och starta quiz',
    (tester) async {
      await app.main();

      // App startup does async init (Hive + DI).
      await tester.pumpAndSettle(const Duration(seconds: 3));

      Future<void> ensureHomeVisible() async {
        final operationCardKeys = <Key>[
          const Key('operation_card_addition'),
          const Key('operation_card_subtraction'),
          const Key('operation_card_multiplication'),
          const Key('operation_card_division'),
        ];

        bool hasCreateProfileButton() {
          return find
              .widgetWithText(ElevatedButton, 'Skapa profil')
              .evaluate()
              .isNotEmpty;
        }

        bool hasOperationCards() {
          for (final key in operationCardKeys) {
            if (find.byKey(key).evaluate().isNotEmpty) return true;
          }
          return false;
        }

        Future<bool> completeOnboardingIfVisible() async {
          final isOnboardingVisible =
              find.text('Hoppa över').evaluate().isNotEmpty &&
                  (find.text('1/2').evaluate().isNotEmpty ||
                      find.text('2/2').evaluate().isNotEmpty);
          if (!isOnboardingVisible) return false;

          // NOTE: The onboarding uses a PageView. Both pages can exist in the
          // widget tree at the same time, so we must avoid targeting widgets
          // from the non-visible page.

          // ---- Onboarding step 2: ops (“Vad vill du räkna?”) ----
          if (find.text('2/2').evaluate().isNotEmpty) {
            final doneButton = find.widgetWithText(ElevatedButton, 'Klar');
            if (doneButton.evaluate().isNotEmpty) {
              await it.tap(
                tester,
                doneButton,
                after: const Duration(seconds: 3),
              );
              await tester.pumpAndSettle(const Duration(seconds: 2));
              return true;
            }

            // Rare race: page jump may not have updated button text yet.
            final nextButton = find.widgetWithText(ElevatedButton, 'Nästa');
            if (nextButton.evaluate().isNotEmpty) {
              await it.tap(
                tester,
                nextButton,
                after: const Duration(seconds: 2),
              );
              await tester.pumpAndSettle(const Duration(seconds: 1));
              return true;
            }
          }

          // ---- Onboarding step 1: grade ----
          if (find.text('1/2').evaluate().isNotEmpty &&
              find.text('Vilken årskurs kör du?').evaluate().isNotEmpty) {
            final gradeDropdown = find.byType(DropdownButton<int?>);
            if (gradeDropdown.evaluate().isNotEmpty) {
              final opened = await it.tryTap(
                tester,
                gradeDropdown,
                after: const Duration(milliseconds: 600),
              );
              if (opened) {
                await tester.pumpAndSettle(const Duration(milliseconds: 400));

                // Prefer Åk 3 for stable coverage.
                final ak3 = find.text('Åk 3');
                if (ak3.evaluate().isNotEmpty) {
                  await it.tap(
                    tester,
                    ak3,
                    after: const Duration(milliseconds: 700),
                  );
                } else {
                  final vetInte = find.text('Vet inte');
                  if (vetInte.evaluate().isNotEmpty) {
                    await it.tap(
                      tester,
                      vetInte,
                      after: const Duration(milliseconds: 600),
                    );
                  }
                }
              }
            }

            final nextButton = find.widgetWithText(ElevatedButton, 'Nästa');
            if (nextButton.evaluate().isNotEmpty) {
              await it.tap(
                tester,
                nextButton,
                after: const Duration(seconds: 2),
              );
              await tester.pumpAndSettle(const Duration(seconds: 1));
              return true;
            }

            // Fallback if button type changes.
            if (find.text('Nästa').evaluate().isNotEmpty) {
              await it.tap(
                tester,
                find.text('Nästa'),
                after: const Duration(seconds: 2),
              );
              await tester.pumpAndSettle(const Duration(seconds: 1));
              return true;
            }
          }

          // Generic escape hatch.
          final skipButton = find.widgetWithText(TextButton, 'Hoppa över');
          if (skipButton.evaluate().isNotEmpty) {
            await it.tap(
              tester,
              skipButton,
              after: const Duration(seconds: 3),
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));
            return true;
          }
          if (find.text('Hoppa över').evaluate().isNotEmpty) {
            await it.tap(
              tester,
              find.text('Hoppa över'),
              after: const Duration(seconds: 3),
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));
            return true;
          }

          return false;
        }

        final deadline = DateTime.now().add(const Duration(seconds: 35));
        while (DateTime.now().isBefore(deadline)) {
          // Onboarding can block the UI.
          await completeOnboardingIfVisible();
          if (hasOperationCards() || hasCreateProfileButton()) return;

          // If we're in Settings, go back.
          if (find.text('Inställningar').evaluate().isNotEmpty) {
            final backButton = find.byType(BackButton);
            if (backButton.evaluate().isNotEmpty) {
              await it.tap(
                tester,
                backButton,
                after: const Duration(seconds: 2),
              );
              await tester.pumpAndSettle(const Duration(seconds: 2));
              if (hasOperationCards()) return;
            }
          }

          // If we're in Quiz, close it.
          if (find.textContaining('Fråga ').evaluate().isNotEmpty) {
            final close = find.byIcon(Icons.close);
            if (close.evaluate().isNotEmpty) {
              await it.tap(tester, close, after: const Duration(seconds: 2));
              await tester.pumpAndSettle(const Duration(seconds: 2));
              if (hasOperationCards()) return;
            }
          }

          // If we're in Results, go back to start.
          final backToStart = find.text('Tillbaka till Start');
          if (backToStart.evaluate().isNotEmpty) {
            await it.tap(
              tester,
              backToStart,
              after: const Duration(seconds: 2),
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));
            if (hasOperationCards()) return;
          }

          await tester.pumpAndSettle(const Duration(milliseconds: 800));
          if (hasOperationCards() || hasCreateProfileButton()) return;
        }

        fail(
          'Could not reach Home or Create Profile. Visible texts: '
          '${it.visibleTexts(tester).take(120).toList()}',
        );
      }

      await ensureHomeVisible();

      // Fresh install path: create a user if none exists.
      final createUserHomeButton =
          find.widgetWithText(ElevatedButton, 'Skapa profil');
      if (createUserHomeButton.evaluate().isNotEmpty) {
        await it.tap(tester, createUserHomeButton);
        await tester.pumpAndSettle();
        // Create user dialog.
        expect(find.text('Skapa användare'), findsWidgets);

        await tester.enterText(find.byType(TextField).first, 'Test');
        await tester.pumpAndSettle();

        await it.tap(
          tester,
          find.text('Skapa'),
          after: const Duration(seconds: 2),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Onboarding can be pushed via post-frame callback after returning to Home.
      await ensureHomeVisible();

      // Start a quiz by tapping the first available operation card.
      final operationCardKeys = <Key>[
        const Key('operation_card_addition'),
        const Key('operation_card_subtraction'),
        const Key('operation_card_multiplication'),
        const Key('operation_card_division'),
      ];

      Finder? chosenOperation;
      for (final key in operationCardKeys) {
        final candidate = find.byKey(key);
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

      await it.tap(tester, chosenOperation, after: const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Quiz screen should show a question title.
      expect(find.textContaining('Fråga '), findsOneWidget);

      // Close the quiz and return.
      await it.tap(
        tester,
        find.byIcon(Icons.close),
        after: const Duration(seconds: 2),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Ensure we're back on home (operation cards visible).
      Finder? anyOperation;
      for (final key in operationCardKeys) {
        final candidate = find.byKey(key);
        if (candidate.evaluate().isNotEmpty) {
          anyOperation = candidate;
          break;
        }
      }
      expect(anyOperation, isNotNull);
    },
  );
}
