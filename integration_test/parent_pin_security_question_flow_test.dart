import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/core/di/injection.dart';
import 'package:siffersafari/data/repositories/local_storage_repository.dart';
import 'package:siffersafari/main.dart' as app;

import 'test_utils.dart' as it;

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
  }

  final skipButton = find.widgetWithText(TextButton, 'Hoppa över');
  if (skipButton.evaluate().isNotEmpty) {
    await it.tap(tester, skipButton);
    await it.settle(tester, _kSettleMedium);
    return true;
  }

  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integration (Parent): skapa PIN och spara säkerhetsfråga (keyboard öppet)',
    (tester) async {
      FlutterErrorDetails? flutterError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        flutterError ??= details;
        if (originalOnError != null) {
          originalOnError.call(details);
        } else {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      void restoreFlutterErrorHandler() {
        FlutterError.onError = originalOnError;
      }

      addTearDown(restoreFlutterErrorHandler);

      Future<void> failWithUiState(String reason) async {
        restoreFlutterErrorHandler();
        fail(
          '$reason. Visible texts: ${it.visibleTexts(tester).take(120).toList()}',
        );
      }

      Future<void> waitFor(
        String label,
        bool Function() condition, {
        Duration timeout = const Duration(seconds: 12),
        Duration step = const Duration(milliseconds: 120),
      }) async {
        final deadline = DateTime.now().add(timeout);
        while (DateTime.now().isBefore(deadline)) {
          if (condition()) return;
          await tester.pump(step);
        }
        await failWithUiState('Timed out waiting for: $label');
      }

      Future<void> ensureHomeReady() async {
        Future<void> maybeCreateProfile() async {
          final createProfile =
              find.widgetWithText(ElevatedButton, 'Skapa profil');
          final createUser =
              find.widgetWithText(ElevatedButton, 'Skapa användare');
          final createButton = createProfile.evaluate().isNotEmpty
              ? createProfile
              : (createUser.evaluate().isNotEmpty ? createUser : null);
          if (createButton == null) return;

          await it.tap(
            tester,
            createButton,
            after: _kSettleShort,
          );
          await tester.pump(_kSettleShort);

          final nameField = find.byType(TextField);
          if (nameField.evaluate().isNotEmpty) {
            await tester.enterText(nameField.first, 'IT Parent');
            await tester.pump(const Duration(milliseconds: 120));
          }

          final create = find.text('Skapa');
          if (create.evaluate().isNotEmpty) {
            await it.tap(
              tester,
              create,
              after: _kSettleMedium,
            );
          }
        }

        Future<void> maybeSkipOnboarding() async {
          final skip = find.text('Hoppa över');
          if (skip.evaluate().isEmpty) return;
          await it.tryTap(
            tester,
            skip,
            after: _kSettleMedium,
          );
        }

        final deadline = DateTime.now().add(const Duration(seconds: 35));
        while (DateTime.now().isBefore(deadline)) {
          if (find.byTooltip('Föräldraläge').evaluate().isNotEmpty) return;

          await maybeCreateProfile();
          while (await _completeOnboardingStepIfVisible(tester)) {
            // complete current onboarding flow
          }
          await maybeSkipOnboarding();
          await tester.pump(const Duration(milliseconds: 150));
        }

        await failWithUiState(
          'Timed out waiting for Home ready (parent mode entry point)',
        );
      }

      await _launchCleanApp(tester);

      await ensureHomeReady();

      // Enter Parent mode.
      final parentModeTooltip = find.byTooltip('Föräldraläge');
      if (parentModeTooltip.evaluate().isNotEmpty) {
        await it.tap(
          tester,
          parentModeTooltip,
          after: _kSettleMedium,
        );
        await tester.pump(_kSettleShort);
      } else {
        // Fallback path: open Settings and tap "Föräldraläge".
        final settingsIcon = find.byIcon(Icons.settings);
        if (settingsIcon.evaluate().isEmpty) {
          await failWithUiState(
            'Neither Settings icon nor Parent Mode tooltip found',
          );
        }
        await it.tap(
          tester,
          settingsIcon,
          after: _kSettleMedium,
        );
        await tester.pump(_kSettleShort);

        final parentModeButton = find.text('Föräldraläge');
        if (parentModeButton.evaluate().isEmpty) {
          await failWithUiState('"Föräldraläge" not found in Settings');
        }
        await it.tap(
          tester,
          parentModeButton,
          after: _kSettleMedium,
        );
        await tester.pump(_kSettleShort);
      }

      await waitFor(
        'Parent PIN screen (Skapa PIN/Ange PIN)',
        () {
          return find.text('Skapa PIN').evaluate().isNotEmpty ||
              find.textContaining('Ange PIN').evaluate().isNotEmpty;
        },
        timeout: const Duration(seconds: 12),
        step: const Duration(milliseconds: 120),
      );

      // Ensure create-PIN flow (clean state expected).
      if (find.textContaining('Ange PIN').evaluate().isNotEmpty) {
        await failWithUiState(
          'Expected create PIN flow, but app asks to enter existing PIN. Clear app data (pm clear) and rerun',
        );
      }
      expect(find.text('Skapa PIN'), findsWidgets);

      // Enter PIN + confirm.
      final pinFields = find.byType(TextField);
      if (pinFields.evaluate().length < 2) {
        await failWithUiState('Expected 2 PIN fields');
      }
      await tester.enterText(pinFields.at(0), '1234');
      await tester.pump(_kSettleShort);
      await tester.enterText(pinFields.at(1), '1234');
      await tester.pump(_kSettleShort);

      final savePin = find.text('Spara PIN');
      if (savePin.evaluate().isEmpty) {
        await failWithUiState('"Spara PIN" button not found');
      }
      await it.tap(tester, savePin, after: _kSettleMedium);
      await tester.pump(_kSettleShort);

      // Recovery setup dialog.
      final dialogTitle = find.text('Sätt säkerhetsfråga');
      await waitFor(
        'Recovery dialog',
        () => dialogTitle.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 12),
        step: const Duration(milliseconds: 120),
      );

      // Focus answer field and keep keyboard open.
      final recoveryDialog = find.byType(AlertDialog);
      expect(recoveryDialog, findsOneWidget);
      final answerField = find.descendant(
        of: recoveryDialog,
        matching: find.byType(TextField),
      );
      if (answerField.evaluate().isEmpty) {
        await failWithUiState('Answer TextField not found in recovery dialog');
      }
      await tester.showKeyboard(answerField.first);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(answerField.first, 'hemligt');
      await tester.pump(const Duration(milliseconds: 120));

      final saveRecovery = find.descendant(
        of: recoveryDialog,
        matching: find.widgetWithText(ElevatedButton, 'Spara säkerhetsfråga'),
      );
      if (saveRecovery.evaluate().isEmpty) {
        await failWithUiState('"Spara säkerhetsfråga" not found');
      }

      // Tap save while keyboard is still up.
      await it.tap(
        tester,
        saveRecovery,
        after: _kSettleShort,
      );

      // Let dialog pop + navigation settle, and verify we didn't hit framework asserts.
      await waitFor(
        'Parent dashboard (Översikt)',
        () => find.text('Översikt').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 20),
        step: const Duration(milliseconds: 120),
      );
      expect(tester.takeException(), isNull);
      if (flutterError != null) {
        fail(
          'FlutterError: ${flutterError!.exceptionAsString()}\n'
          '${flutterError!.stack ?? ''}',
        );
      }

      // Expected destination.
      expect(find.text('Översikt'), findsWidgets);

      // Extra settle for delayed overlay issues.
      await it.settle(tester, _kSettleMedium);
      expect(tester.takeException(), isNull);
      if (flutterError != null) {
        fail(
          'FlutterError (late): ${flutterError!.exceptionAsString()}\n'
          '${flutterError!.stack ?? ''}',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
