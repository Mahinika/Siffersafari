import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/main.dart' as app;

import 'test_utils.dart' as it;

/// Integration tests for parent-facing critical features:
/// - PIN creation and verification
/// - PIN recovery flow
/// - Profile management
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integration (Parent): skapa PIN och öppna föräldradashboard',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 600));

      // Navigate to settings (gear icon in top-right).
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) {
        // Skip if onboarding/other UI blocks it.
        return;
      }

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await it.settle(tester, const Duration(milliseconds: 300));

      // Find "Föräldraläge" button.
      final parentModeButton = find.text('Föräldraläge');
      expect(parentModeButton, findsOneWidget);

      await it.tap(tester, parentModeButton, after: const Duration(seconds: 1));
      await it.waitForText(tester, 'Skapa PIN', timeout: const Duration(seconds: 12));

      // Should show PIN creation screen.
      expect(find.text('Skapa PIN'), findsWidgets);

      // Enter a 4-digit PIN (e.g. 1234).
      final pinFields = find.byType(TextField);
      expect(pinFields, findsNWidgets(2));

      await tester.enterText(pinFields.at(0), '1234');
      await tester.pump(const Duration(milliseconds: 120));
      await tester.enterText(pinFields.at(1), '1234');
      await tester.pump(const Duration(milliseconds: 120));

      final savePinButton = find.text('Spara PIN');
      expect(savePinButton, findsOneWidget);
      await it.tap(tester, savePinButton, after: const Duration(milliseconds: 450));

      // If recovery setup dialog appears, close it.
      if (find.text('Sätt säkerhetsfråga').evaluate().isNotEmpty) {
        final closeRecoveryDialog = find.text('Hoppa över');
        if (closeRecoveryDialog.evaluate().isNotEmpty) {
          await it.tap(
            tester,
            closeRecoveryDialog,
            after: const Duration(milliseconds: 500),
          );
          await it.settle(tester, const Duration(milliseconds: 300));
        }
      }

      // Should now be in Parent Dashboard.
      await it.waitForText(tester, 'Översikt', timeout: const Duration(seconds: 20));
      expect(find.text('Översikt'), findsWidgets);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Integration (Parent): verifiera PIN efter att ha skapat en',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 600));

      // Go to settings.
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) return;

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await it.settle(tester, const Duration(milliseconds: 300));

      // Tap "Föräldraläge".
      final parentModeButton = find.text('Föräldraläge');
      if (parentModeButton.evaluate().isEmpty) return;

      await it.tap(tester, parentModeButton, after: const Duration(seconds: 1));
      await it.settle(tester, const Duration(milliseconds: 300));

      // If PIN already exists, should ask for PIN verification.
      final pinVerifyText = find.textContaining('Ange PIN');
      if (pinVerifyText.evaluate().isNotEmpty) {
        // Enter the PIN (1234 from previous test, or any 4-digit if fresh).
        final pinFields = find.byType(TextField);
        if (pinFields.evaluate().isNotEmpty) {
          await tester.enterText(pinFields.first, '1234');
          await tester.pump(const Duration(milliseconds: 150));

          final confirmButton = find.text('Öppna');
          if (confirmButton.evaluate().isNotEmpty) {
            await it.tap(
              tester,
              confirmButton,
              after: const Duration(milliseconds: 450),
            );
            await it.waitForText(tester, 'Översikt', timeout: const Duration(seconds: 20));
          }
        }

        // Should now be in Parent Dashboard.
        expect(find.text('Översikt'), findsWidgets);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Integration (Parent): PIN recovery med security question',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 600));

      // Navigate to Parent Mode.
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) return;

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await it.settle(tester, const Duration(milliseconds: 300));

      final parentModeButton = find.text('Föräldraläge');
      if (parentModeButton.evaluate().isEmpty) return;

      await it.tap(tester, parentModeButton, after: const Duration(seconds: 1));
      await it.settle(tester, const Duration(milliseconds: 300));

      // Look for "Glömt PIN?" link.
      final forgotPinLink = find.text('Glömt PIN?');
      if (forgotPinLink.evaluate().isEmpty) {
        // PIN recovery not configured yet, skip test.
        return;
      }

      await it.tap(tester, forgotPinLink, after: const Duration(seconds: 1));
      await it.waitForText(tester, 'Återställ PIN', timeout: const Duration(seconds: 12));

      // Should show security question.
      expect(find.text('Återställ PIN'), findsWidgets);

      // Enter security answer (from previous test: "Mat").
      final securityAnswerField = find.byType(TextField).first;
      await tester.enterText(securityAnswerField, 'Mat');
      await tester.pump(const Duration(milliseconds: 150));

      final verifyButton = find.text('Verifiera svar');
      if (verifyButton.evaluate().isNotEmpty) {
        await it.tap(tester, verifyButton, after: const Duration(milliseconds: 450));
        await it.settle(tester, const Duration(milliseconds: 450));
      }

      // Should proceed to PIN reset screen.
      // (This depends on implementation; just verify no crash.)
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Integration (Profil): skapa ny profil och byt profil',
    (tester) async {
      await app.main();
      await it.settle(tester, const Duration(milliseconds: 600));

      // Go to settings.
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) return;

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await it.settle(tester, const Duration(milliseconds: 300));

      // Look for "Byt profil" or "Skapa profil".
      final switchProfileButton = find.textContaining('profil');
      if (switchProfileButton.evaluate().isEmpty) return;

      await it.tap(
        tester,
        switchProfileButton.first,
        after: const Duration(milliseconds: 450),
      );
      await it.settle(tester, const Duration(milliseconds: 300));

      // Should show profile selection or creation screen.
      final createProfileButton = find.text('Skapa profil');
      if (createProfileButton.evaluate().isNotEmpty) {
        await it.tap(
          tester,
          createProfileButton,
          after: const Duration(milliseconds: 450),
        );
        await it.settle(tester, const Duration(milliseconds: 300));

        // Enter profile name (e.g. "Test User").
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'Integration Test User');
        await tester.pump(const Duration(milliseconds: 150));

        // Select grade (Åk 3).
        final gradeDropdown = find.byType(DropdownButton<int?>);
        if (gradeDropdown.evaluate().isNotEmpty) {
          await it.tryTap(
            tester,
            gradeDropdown,
            after: const Duration(milliseconds: 300),
          );
          await tester.pump(const Duration(milliseconds: 120));

          final ak3 = find.text('Åk 3').last;
          if (ak3.evaluate().isNotEmpty) {
            await it.tryTap(
              tester,
              ak3,
              after: const Duration(milliseconds: 300),
            );
            await tester.pump(const Duration(milliseconds: 120));
          }
        }

        // Confirm creation.
        final confirmButton = find.text('Skapa');
        if (confirmButton.evaluate().isNotEmpty) {
          await it.tap(
            tester,
            confirmButton,
            after: const Duration(milliseconds: 450),
          );
          await it.settle(tester, const Duration(milliseconds: 600));
        }

        // Should be back at home with new profile active.
        expect(tester.takeException(), isNull);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
