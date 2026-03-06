import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/main.dart' as app;

import 'test_utils.dart' as it;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integration (smoke): skapa användare vid behov och starta quiz',
    (tester) async {
      await app.main();

      // App startup does async init (Hive + DI).
      await it.settle(tester, const Duration(milliseconds: 1200));

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
              await it.tap(tester, doneButton);
              await it.settle(tester, const Duration(milliseconds: 600));
              return true;
            }

            // Rare race: page jump may not have updated button text yet.
            final nextButton = find.widgetWithText(ElevatedButton, 'Nästa');
            if (nextButton.evaluate().isNotEmpty) {
              await it.tap(tester, nextButton);
              await it.settle(tester, const Duration(milliseconds: 450));
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
                await it.settle(tester, const Duration(milliseconds: 300));

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
              await it.tap(tester, nextButton);
              await it.settle(tester, const Duration(milliseconds: 450));
              return true;
            }

            // Fallback if button type changes.
            if (find.text('Nästa').evaluate().isNotEmpty) {
              await it.tap(tester, find.text('Nästa'));
              await it.settle(tester, const Duration(milliseconds: 450));
              return true;
            }
          }

          // Generic escape hatch.
          final skipButton = find.widgetWithText(TextButton, 'Hoppa över');
          if (skipButton.evaluate().isNotEmpty) {
            await it.tap(tester, skipButton);
            await it.settle(tester, const Duration(milliseconds: 700));
            return true;
          }
          if (find.text('Hoppa över').evaluate().isNotEmpty) {
            await it.tap(tester, find.text('Hoppa över'));
            await it.settle(tester, const Duration(milliseconds: 700));
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
              await it.tap(tester, backButton);
              await it.settle(tester, const Duration(milliseconds: 700));
              if (hasOperationCards()) return;
            }
          }

          // If we're in Quiz, close it.
          if (find.textContaining('Fråga ').evaluate().isNotEmpty) {
            final close = find.byIcon(Icons.close);
            if (close.evaluate().isNotEmpty) {
              await it.tap(tester, close);
              await it.settle(tester, const Duration(milliseconds: 700));
              if (hasOperationCards()) return;
            }
          }

          // If we're in Results, go back to start.
          final backToStart = find.text('Tillbaka till Start');
          if (backToStart.evaluate().isNotEmpty) {
            await it.tap(tester, backToStart);
            await it.settle(tester, const Duration(milliseconds: 700));
            if (hasOperationCards()) return;
          }

          await tester.pump(const Duration(milliseconds: 120));
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
        await it.settle(tester, const Duration(milliseconds: 400));
        // Create user dialog.
        await it.waitFor(
          tester,
          'create-user dialog',
          () => find.text('Skapa användare').evaluate().isNotEmpty,
        );

        await tester.enterText(find.byType(TextField).first, 'Test');
        await it.settle(tester, const Duration(milliseconds: 250));

        await it.tap(tester, find.text('Skapa'));
        await ensureHomeVisible();
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

      await it.tap(tester, chosenOperation);
      await it.waitFor(
        tester,
        'quiz question visible',
        () => find.textContaining('Fråga ').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 12),
      );

      // Quiz screen should show a question title.
      expect(find.textContaining('Fråga '), findsOneWidget);

      // Close the quiz and return.
      await it.tap(tester, find.byIcon(Icons.close));
      await it.waitFor(
        tester,
        'home operation cards visible',
        () {
          for (final key in operationCardKeys) {
            if (find.byKey(key).evaluate().isNotEmpty) return true;
          }
          return false;
        },
        timeout: const Duration(seconds: 12),
      );

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

  testWidgets(
    'Smoke: app startar och hittar huvudskärm',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 1200));
      await it.waitFor(
        tester,
        'app started (onboarding or home)',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Vilken årskurs kör du?').evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_addition')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_subtraction')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_multiplication')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_division')).evaluate().isNotEmpty ||
            find.text('Skapa profil').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 35),
      );

      // Verify app is running and we can find key UI elements.
      // Either we're in onboarding or we can see operation cards.
      final onboardingVisible = find.text('Hoppa över').evaluate().isNotEmpty ||
          find.text('Vilken årskurs kör du?').evaluate().isNotEmpty;

      final homeVisible = find
              .byKey(const Key('operation_card_addition'))
              .evaluate()
              .isNotEmpty ||
          find
              .byKey(const Key('operation_card_subtraction'))
              .evaluate()
              .isNotEmpty ||
          find
              .byKey(const Key('operation_card_multiplication'))
              .evaluate()
              .isNotEmpty ||
          find
              .byKey(const Key('operation_card_division'))
              .evaluate()
              .isNotEmpty ||
          find.text('Skapa profil').evaluate().isNotEmpty;

      expect(
        onboardingVisible || homeVisible,
        isTrue,
        reason: 'App should show either onboarding or home screen',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Smoke: öppna inställningar och gå tillbaka',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 1200));
      await it.waitFor(
        tester,
        'home/onboarding visible',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Skapa profil').evaluate().isNotEmpty ||
            find.byIcon(Icons.settings).evaluate().isNotEmpty ||
            find.byTooltip('Föräldraläge').evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_addition')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_subtraction')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_multiplication')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_division')).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 35),
      );

      // Navigate through onboarding if visible.
      if (find.text('Hoppa över').evaluate().isNotEmpty) {
        await it.tap(tester, find.text('Hoppa över'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      // Find settings icon (gear icon).
      Future<void> maybeCreateProfile() async {
        final createProfileButton =
            find.widgetWithText(ElevatedButton, 'Skapa profil');
        if (createProfileButton.evaluate().isEmpty) return;

        await it.tap(tester, createProfileButton);
        await it.settle(tester, const Duration(milliseconds: 400));
        await tester.enterText(find.byType(TextField).first, 'SmokeUser');
        await it.settle(tester, const Duration(milliseconds: 250));
        await it.tap(tester, find.text('Skapa'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      Future<void> openSettings() async {
        final candidates = <Finder>[
          find.byIcon(Icons.settings),
          find.byTooltip('Inställningar'),
          find.text('Inställningar'),
        ];

        for (final candidate in candidates) {
          if (candidate.evaluate().isEmpty) continue;
          await it.tap(tester, candidate.first);
          return;
        }

        fail(
          'Could not find a Settings entry point. Visible texts: '
          '${it.visibleTexts(tester).take(120).toList()}',
        );
      }

      await maybeCreateProfile();

      await openSettings();
      await it.waitForText(tester, 'Inställningar');

      // Verify we're in settings.
      expect(
        find.text('Inställningar'),
        findsOneWidget,
      );

      // Go back.
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await it.tap(tester, backButton);
      await it.waitFor(
        tester,
        'home operation cards',
        () => find.byKey(const Key('operation_card_addition')).evaluate().isNotEmpty,
      );

      // Verify we're back on home (operation cards visible).
      final anyOperationCard = find.byKey(const Key('operation_card_addition'));
      expect(anyOperationCard, findsOneWidget);
    },
    timeout: const Timeout(
      Duration(
        minutes: 2,
      ),
    ),
  );

  testWidgets(
    'Smoke: achievement-screen kan visas',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 1200));
      await it.waitFor(
        tester,
        'home/onboarding visible',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Skapa profil').evaluate().isNotEmpty ||
            find.byIcon(Icons.emoji_events).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_addition')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_subtraction')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_multiplication')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_division')).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 35),
      );

      // Skip onboarding if visible.
      if (find.text('Hoppa över').evaluate().isNotEmpty) {
        await it.tap(tester, find.text('Hoppa över'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      // Create profile if none exists.
      final createProfileButton =
          find.widgetWithText(ElevatedButton, 'Skapa profil');
      if (createProfileButton.evaluate().isNotEmpty) {
        await it.tap(tester, createProfileButton);
        await it.settle(tester, const Duration(milliseconds: 400));
        await tester.enterText(find.byType(TextField).first, 'AchievementUser');
        await it.settle(tester, const Duration(milliseconds: 250));
        await it.tap(tester, find.text('Skapa'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      // Find trophy icon (achievements).
      final trophyIcon = find.byIcon(Icons.emoji_events);
      if (trophyIcon.evaluate().isEmpty) {
        // Fallback: try finding by text.
        final achievementsText = find.text('Achievements');
        expect(
          achievementsText,
          findsWidgets,
          reason: 'Trophy icon or Achievements text should be visible',
        );
        await it.tap(tester, achievementsText.first);
      } else {
        await it.tap(tester, trophyIcon.first);
      }

      await it.settle(tester, const Duration(milliseconds: 700));

      // Verify we're on achievements screen (look for common UI elements).
      final achievementsTitle =
          find.textContaining('Achievements').evaluate().isNotEmpty ||
              find.text('Inga upplåsta').evaluate().isNotEmpty ||
              find.byIcon(Icons.emoji_events).evaluate().isNotEmpty;

      expect(
        achievementsTitle,
        isTrue,
        reason: 'Achievements screen should be visible',
      );

      // No need to navigate back in a smoke test.
    },
    timeout: const Timeout(
      Duration(
        minutes: 2,
      ),
    ),
  );

  testWidgets(
    'Smoke: profile switcher kan öppnas',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 1200));
      await it.waitFor(
        tester,
        'home/onboarding visible',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Skapa profil').evaluate().isNotEmpty ||
            find.byIcon(Icons.arrow_drop_down).evaluate().isNotEmpty ||
            find.byKey(const Key('profile_selector')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_addition')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_subtraction')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_multiplication')).evaluate().isNotEmpty ||
            find.byKey(const Key('operation_card_division')).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 35),
      );

      // Skip onboarding.
      if (find.text('Hoppa över').evaluate().isNotEmpty) {
        await it.tap(tester, find.text('Hoppa över'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      // Create profile if none exists.
      final createProfileButton =
          find.widgetWithText(ElevatedButton, 'Skapa profil');
      if (createProfileButton.evaluate().isNotEmpty) {
        await it.tap(tester, createProfileButton);
        await it.settle(tester, const Duration(milliseconds: 400));
        await tester.enterText(
          find.byType(TextField).first,
          'ProfileSwitchUser',
        );
        await it.settle(tester, const Duration(milliseconds: 250));
        await it.tap(tester, find.text('Skapa'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      // Find profile name display (usually at top of home screen).
      // Look for the profile dropdown or name text.
      final profileDropdown = find.byKey(const Key('profile_selector'));
      if (profileDropdown.evaluate().isEmpty) {
        // Fallback: look for name text followed by dropdown arrow.
        final arrowDown = find.byIcon(Icons.arrow_drop_down);
        expect(
          arrowDown,
          findsWidgets,
          reason: 'Profile dropdown should be visible on home screen',
        );
        await it.tap(
          tester,
          arrowDown.first,
        );
      } else {
        await it.tap(tester, profileDropdown.first);
      }

      await it.settle(tester, const Duration(milliseconds: 450));

      // Verify dropdown menu is visible (look for "Skapa ny profil" option).
      final createNewOption = find.text('Skapa ny profil');
      await it.waitForText(tester, 'Skapa ny profil');
      expect(
        createNewOption,
        findsOneWidget,
        reason: 'Profile switcher menu should show "Skapa ny profil" option',
      );

      // Tap outside to close dropdown (tap on scrim or press back).
      await tester.tapAt(const Offset(10, 10));
      await it.settle(tester, const Duration(milliseconds: 250));
    },
    timeout: const Timeout(
      Duration(
        minutes: 2,
      ),
    ),
  );
}
