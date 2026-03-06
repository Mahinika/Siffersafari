import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/main.dart' as app;

import 'test_utils.dart' as it;

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
            after: const Duration(milliseconds: 300),
          );
          await tester.pump(const Duration(milliseconds: 200));

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
              after: const Duration(milliseconds: 500),
            );
          }
        }

        Future<void> maybeSkipOnboarding() async {
          final skip = find.text('Hoppa över');
          if (skip.evaluate().isEmpty) return;
          await it.tryTap(
            tester,
            skip,
            after: const Duration(milliseconds: 600),
          );
        }

        await waitFor(
          'Home ready (settings icon or parent mode tooltip)',
          () {
            return find.byIcon(Icons.settings).evaluate().isNotEmpty ||
                find.byTooltip('Föräldraläge').evaluate().isNotEmpty;
          },
          timeout: const Duration(seconds: 25),
          step: const Duration(milliseconds: 150),
        );

        // If first-run UI is visible, resolve it quickly.
        await maybeCreateProfile();
        await maybeSkipOnboarding();

        await waitFor(
          'Home ready (after first-run)',
          () {
            return find.byIcon(Icons.settings).evaluate().isNotEmpty ||
                find.byTooltip('Föräldraläge').evaluate().isNotEmpty;
          },
          timeout: const Duration(seconds: 20),
          step: const Duration(milliseconds: 150),
        );
      }

      await app.main();
      await tester.pump(const Duration(milliseconds: 400));

      await ensureHomeReady();

      // Enter Parent mode.
      final parentModeTooltip = find.byTooltip('Föräldraläge');
      if (parentModeTooltip.evaluate().isNotEmpty) {
        await it.tap(
          tester,
          parentModeTooltip,
          after: const Duration(milliseconds: 400),
        );
        await tester.pump(const Duration(milliseconds: 200));
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
          after: const Duration(milliseconds: 500),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final parentModeButton = find.text('Föräldraläge');
        if (parentModeButton.evaluate().isEmpty) {
          await failWithUiState('"Föräldraläge" not found in Settings');
        }
        await it.tap(
          tester,
          parentModeButton,
          after: const Duration(milliseconds: 500),
        );
        await tester.pump(const Duration(milliseconds: 200));
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
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(pinFields.at(1), '1234');
      await tester.pump(const Duration(milliseconds: 200));

      final savePin = find.text('Spara PIN');
      if (savePin.evaluate().isEmpty) {
        await failWithUiState('"Spara PIN" button not found');
      }
      await it.tap(tester, savePin, after: const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));

      // Recovery setup dialog.
      final dialogTitle = find.text('Sätt säkerhetsfråga');
      await waitFor(
        'Recovery dialog',
        () => dialogTitle.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 12),
        step: const Duration(milliseconds: 120),
      );

      // Focus answer field and keep keyboard open.
      final answerField = find.byType(TextField);
      if (answerField.evaluate().isEmpty) {
        await failWithUiState('Answer TextField not found in recovery dialog');
      }
      await it.tap(tester, answerField.first,
          after: const Duration(milliseconds: 300),
        );
      await tester.showKeyboard(answerField.first);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(answerField.first, 'hemligt');
      await tester.pump(const Duration(milliseconds: 120));

      final saveRecovery = find.text('Spara säkerhetsfråga');
      if (saveRecovery.evaluate().isEmpty) {
        await failWithUiState('"Spara säkerhetsfråga" not found');
      }

      // Tap save while keyboard is still up.
      await it.tap(tester, saveRecovery,
          after: const Duration(milliseconds: 250),
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
      await it.settle(tester, const Duration(milliseconds: 600));
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
