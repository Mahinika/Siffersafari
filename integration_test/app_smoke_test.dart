import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/core/di/injection.dart';
import 'package:siffersafari/data/repositories/local_storage_repository.dart';
import 'package:siffersafari/main.dart' as app;

import 'test_utils.dart' as it;

const bool _runExtendedSmoke =
    bool.fromEnvironment('FULL_SMOKE', defaultValue: false);

const _kSettleShort = Duration(milliseconds: 250);
const _kSettleMedium = Duration(milliseconds: 400);
const _kSettleLong = Duration(milliseconds: 600);

String? _activeOnboardingStep(WidgetTester tester) {
  final stepPattern = RegExp(r'^\d+/\d+$');

  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final text = widget.data?.trim();
    if (text != null && stepPattern.hasMatch(text)) {
      return text;
    }
  }

  return null;
}

bool _isVisible(Finder finder) => finder.hitTestable().evaluate().isNotEmpty;

Future<void> _launchCleanApp(WidgetTester tester) async {
  await app.main();
  await it.settle(tester, _kSettleLong);

  if (getIt.isRegistered<LocalStorageRepository>()) {
    await getIt<LocalStorageRepository>().clearAllData();
    await tester.pump(const Duration(milliseconds: 120));
  }

  await app.main();
  await it.settle(tester, _kSettleLong);
}

Future<bool> _completeOnboardingStepIfVisible(WidgetTester tester) async {
  final activeStep = _activeOnboardingStep(tester);
  final gradeTitle = find.text('Vilken årskurs kör du?');
  final readingTitle = find.text('Kan barnet läsa?');
  final opsTitle = find.text('Vad vill du räkna först?');

  if (_isVisible(readingTitle)) {
    final noButton = find.text('Nej').hitTestable();
    if (noButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(noButton.first);
      await tester.tap(noButton.first);
      await it.settle(tester, _kSettleMedium);
      return true;
    }
  }

  if ((activeStep?.startsWith('1/') ?? true) && _isVisible(gradeTitle)) {
    final nextButton = find.widgetWithText(ElevatedButton, 'Nästa');
    if (nextButton.evaluate().isNotEmpty) {
      await it.tap(tester, nextButton);
      await it.settle(tester, _kSettleMedium);
      return true;
    }
  }

  if (_isVisible(opsTitle) ||
      activeStep?.startsWith('3/') == true ||
      ((activeStep?.startsWith('2/') ?? false) && !_isVisible(readingTitle))) {
    final doneButton = find.widgetWithText(ElevatedButton, 'Starta');
    if (doneButton.evaluate().isNotEmpty) {
      await it.tap(tester, doneButton);
      await it.settle(tester, _kSettleMedium);
      return true;
    }

    final nextButton = find.widgetWithText(ElevatedButton, 'Nästa');
    if (nextButton.evaluate().isNotEmpty) {
      await it.tap(tester, nextButton);
      await it.settle(tester, _kSettleMedium);
      return true;
    }
  }

  final skipButton = find.widgetWithText(TextButton, 'Hoppa över');
  if (skipButton.evaluate().isNotEmpty) {
    await it.tap(tester, skipButton);
    await it.settle(tester, _kSettleMedium);
    return true;
  }

  return false;
}

Future<void> _drainUiAnimations(WidgetTester tester) async {
  await it.settle(tester, _kSettleShort);
}

Future<void> _cleanupAfterTest(WidgetTester tester) async {
  // Replace the app tree to dispose active controllers/tickers before invariant checks.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(_kSettleShort);
  await _drainUiAnimations(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integration (smoke): skapa användare vid behov och starta quiz',
    (tester) async {
      addTearDown(() async {
        await _cleanupAfterTest(tester);
      });
      await _launchCleanApp(tester);

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

        final deadline = DateTime.now().add(const Duration(seconds: 35));
        while (DateTime.now().isBefore(deadline)) {
          await _completeOnboardingStepIfVisible(tester);
          if (hasOperationCards() || hasCreateProfileButton()) return;

          // If we're in Settings, go back.
          if (find.text('Inställningar').evaluate().isNotEmpty) {
            final backButton = find.byType(BackButton);
            if (backButton.evaluate().isNotEmpty) {
              await it.tap(tester, backButton);
              await it.settle(tester, _kSettleMedium);
              if (hasOperationCards()) return;
            }
          }

          // If we're in Quiz, close it.
          if (find.textContaining('Fråga ').evaluate().isNotEmpty) {
            final close = find.byIcon(Icons.close);
            if (close.evaluate().isNotEmpty) {
              await it.tap(tester, close);
              await it.settle(tester, _kSettleMedium);
              if (hasOperationCards()) return;
            }
          }

          // If we're in Results, go back to start.
          final backToStart = find.text('Tillbaka till Start');
          if (backToStart.evaluate().isNotEmpty) {
            await it.tap(tester, backToStart);
            await it.settle(tester, _kSettleMedium);
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
        await it.settle(tester, _kSettleShort);
        // Create user dialog.
        await it.waitFor(
          tester,
          'create-user dialog',
          () => find.text('Skapa användare').evaluate().isNotEmpty,
        );

        await tester.enterText(find.byType(TextField).first, 'Test');
        await it.settle(tester, _kSettleShort);

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
    },
  );

  testWidgets(
    'Smoke: app startar och hittar huvudskärm',
    (tester) async {
      addTearDown(() async {
        await _cleanupAfterTest(tester);
      });
      await _launchCleanApp(tester);
      await it.waitFor(
        tester,
        'app started (onboarding or home)',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Nu kör vi!').evaluate().isNotEmpty ||
            find.text('Vilken årskurs kör du?').evaluate().isNotEmpty ||
            find.text('Kan barnet läsa?').evaluate().isNotEmpty ||
            find.text('Vad vill du räkna först?').evaluate().isNotEmpty ||
            find
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
            find.text('Skapa profil').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 35),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Smoke: öppna inställningar och gå tillbaka',
    (tester) async {
      addTearDown(() async {
        await _cleanupAfterTest(tester);
      });
      await _launchCleanApp(tester);
      await it.waitFor(
        tester,
        'home/onboarding visible',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Nu kör vi!').evaluate().isNotEmpty ||
            find.text('Skapa profil').evaluate().isNotEmpty ||
            find.byIcon(Icons.settings).evaluate().isNotEmpty ||
            find.byTooltip('Föräldraläge').evaluate().isNotEmpty ||
            find
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
                .isNotEmpty,
        timeout: const Duration(seconds: 35),
      );

      while (await _completeOnboardingStepIfVisible(tester)) {
        // complete current onboarding flow
      }

      // Find settings icon (gear icon).
      Future<void> maybeCreateProfile() async {
        final createProfileButton =
            find.widgetWithText(ElevatedButton, 'Skapa profil');
        if (createProfileButton.evaluate().isEmpty) return;

        await it.tap(tester, createProfileButton);
        await it.settle(tester, _kSettleShort);
        await tester.enterText(find.byType(TextField).first, 'SmokeUser');
        await it.settle(tester, _kSettleShort);
        await it.tap(tester, find.text('Skapa'));
        await it.settle(tester, _kSettleMedium);
      }

      Future<void> maybeSkipOnboarding() async {
        if (find.text('Hoppa över').evaluate().isEmpty) return;
        await it.tap(tester, find.text('Hoppa över'));
        await it.settle(tester, _kSettleMedium);
      }

      Future<void> ensureParentDashboard() async {
        await maybeCreateProfile();
        await maybeSkipOnboarding();

        await it.waitFor(
          tester,
          'parent mode entry point',
          () => find.byTooltip('Föräldraläge').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 35),
        );

        await it.tap(tester, find.byTooltip('Föräldraläge'));
        await it.settle(tester, _kSettleMedium);

        if (find.text('Skapa PIN').evaluate().isNotEmpty) {
          final pinFields = find.byType(TextField);
          if (pinFields.evaluate().length < 2) {
            fail('Expected at least two PIN fields in create-PIN flow.');
          }
          await tester.enterText(pinFields.at(0), '1234');
          await tester.enterText(pinFields.at(1), '1234');
          await it.settle(tester, _kSettleShort);
          await it.tap(tester, find.text('Spara PIN'));
          await it.settle(tester, _kSettleMedium);

          if (find.text('Sätt säkerhetsfråga').evaluate().isNotEmpty) {
            final recoveryDialog = find.byType(AlertDialog);
            if (recoveryDialog.evaluate().isEmpty) {
              fail('Expected recovery dialog after creating PIN.');
            }
            final answerField = find.descendant(
              of: recoveryDialog,
              matching: find.byType(TextField),
            );
            if (answerField.evaluate().isEmpty) {
              fail('Expected answer field in recovery dialog.');
            }
            await tester.enterText(answerField, 'hemligt');
            await it.settle(tester, _kSettleShort);
            await it.tap(
              tester,
              find.descendant(
                of: recoveryDialog,
                matching:
                    find.widgetWithText(ElevatedButton, 'Spara säkerhetsfråga'),
              ),
            );
          }
        } else if (find.text('Ange PIN').evaluate().isNotEmpty) {
          final pinField = find.byType(TextField).first;
          await tester.enterText(pinField, '1234');
          await it.settle(tester, _kSettleShort);
          await it.tap(tester, find.text('Öppna'));
        }

        await it.waitForText(tester, 'Översikt');
      }

      await ensureParentDashboard();

      await it.tap(tester, find.byTooltip('Inställningar'));
      await it.waitForText(tester, 'Inställningar');

      // Go back.
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isEmpty) {
        fail('Expected back button in settings.');
      }
      await it.tap(tester, backButton);
      await it.waitForText(tester, 'Översikt');
    },
    timeout: const Timeout(
      Duration(
        minutes: 2,
      ),
    ),
  );

  testWidgets(
    'Smoke: hemvyn visar spelkort efter profilskapande',
    (tester) async {
      addTearDown(() async {
        await _cleanupAfterTest(tester);
      });
      await _launchCleanApp(tester);

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

      while (await _completeOnboardingStepIfVisible(tester)) {
        // complete current onboarding flow
      }

      expect(find.byKey(const Key('operation_card_addition')), findsOneWidget);
    },
    timeout: const Timeout(
      Duration(
        minutes: 2,
      ),
    ),
    skip: !_runExtendedSmoke,
  );

  testWidgets(
    'Smoke: profile switcher kan öppnas',
    (tester) async {
      addTearDown(() async {
        await _cleanupAfterTest(tester);
      });
      await _launchCleanApp(tester);
      await it.waitFor(
        tester,
        'home/onboarding visible',
        () =>
            find.text('Hoppa över').evaluate().isNotEmpty ||
            find.text('Nu kör vi!').evaluate().isNotEmpty ||
            find.text('Skapa profil').evaluate().isNotEmpty ||
            find.byIcon(Icons.arrow_drop_down).evaluate().isNotEmpty ||
            find.byKey(const Key('profile_selector')).evaluate().isNotEmpty ||
            find
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
                .isNotEmpty,
        timeout: const Duration(seconds: 35),
      );

      Future<void> maybeSkipOnboarding() async {
        while (await _completeOnboardingStepIfVisible(tester)) {
          // complete current onboarding flow
        }
      }

      Future<void> maybeCreateProfile(String name) async {
        final createProfileButton =
            find.widgetWithText(ElevatedButton, 'Skapa profil');
        if (createProfileButton.evaluate().isEmpty) return;
        await it.tap(tester, createProfileButton);
        await it.settle(tester, const Duration(milliseconds: 400));
        await tester.enterText(find.byType(TextField).first, name);
        await it.settle(tester, const Duration(milliseconds: 250));
        await it.tap(tester, find.text('Skapa'));
        await it.settle(tester, const Duration(milliseconds: 700));
      }

      Future<void> ensureParentDashboard() async {
        await maybeCreateProfile('ProfileSwitchUser');
        await maybeSkipOnboarding();
        await it.waitFor(
          tester,
          'parent mode entry point',
          () => find.byTooltip('Föräldraläge').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 35),
        );
        await it.tap(tester, find.byTooltip('Föräldraläge'));
        await it.settle(tester, const Duration(milliseconds: 500));

        if (find.text('Skapa PIN').evaluate().isNotEmpty) {
          final pinFields = find.byType(TextField);
          if (pinFields.evaluate().length < 2) {
            fail('Expected at least two PIN fields in create-PIN flow.');
          }
          await tester.enterText(pinFields.at(0), '1234');
          await tester.enterText(pinFields.at(1), '1234');
          await it.settle(tester, const Duration(milliseconds: 250));
          await it.tap(tester, find.text('Spara PIN'));
          await it.settle(tester, const Duration(milliseconds: 500));

          if (find.text('Sätt säkerhetsfråga').evaluate().isNotEmpty) {
            final recoveryDialog = find.byType(AlertDialog);
            if (recoveryDialog.evaluate().isEmpty) {
              fail('Expected recovery dialog after creating PIN.');
            }
            final answerField = find.descendant(
              of: recoveryDialog,
              matching: find.byType(TextField),
            );
            if (answerField.evaluate().isEmpty) {
              fail('Expected answer field in recovery dialog.');
            }
            await tester.enterText(answerField, 'hemligt');
            await it.settle(tester, const Duration(milliseconds: 200));
            await it.tap(
              tester,
              find.descendant(
                of: recoveryDialog,
                matching:
                    find.widgetWithText(ElevatedButton, 'Spara säkerhetsfråga'),
              ),
            );
          }
        } else if (find.text('Ange PIN').evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextField).first, '1234');
          await it.settle(tester, const Duration(milliseconds: 200));
          await it.tap(tester, find.text('Öppna'));
        }

        await it.waitForText(tester, 'Översikt');
      }

      await ensureParentDashboard();
      await it.tap(tester, find.byTooltip('Inställningar'));
      await it.waitForText(tester, 'Inställningar');

      await it.tap(tester, find.text('Skapa användare'));
      await it.settle(tester, const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField).first, 'AndraUser');
      await it.settle(tester, const Duration(milliseconds: 250));
      await it.tap(tester, find.text('Skapa'));
      await it.settle(tester, const Duration(milliseconds: 700));

      final userDropdown = find.byType(DropdownButton<String>);
      final dropdownFallback = find.byType(DropdownButton);
      if (userDropdown.evaluate().isNotEmpty) {
        await it.tap(tester, userDropdown.first);
      } else {
        await it.tap(tester, dropdownFallback.first);
      }

      await it.waitForText(tester, 'AndraUser');
      expect(find.text('AndraUser'), findsWidgets);

      await tester.tapAt(const Offset(10, 10));
      await it.settle(tester, const Duration(milliseconds: 250));
    },
    timeout: const Timeout(
      Duration(
        minutes: 2,
      ),
    ),
    skip: !_runExtendedSmoke,
  );
}
