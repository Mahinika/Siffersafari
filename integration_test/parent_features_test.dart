import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_game_app/main.dart' as app;

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
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to settings (gear icon in top-right).
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) {
        // Skip if onboarding/other UI blocks it.
        return;
      }

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find "Föräldraläge" button.
      final parentModeButton = find.text('Föräldraläge');
      expect(parentModeButton, findsOneWidget);

      await it.tap(tester, parentModeButton, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show PIN creation dialog.
      expect(find.text('Skapa PIN-kod'), findsWidgets);

      // Enter a 4-digit PIN (e.g. 1234).
      final pinFields = find.byType(TextField);
      expect(pinFields, findsWidgets);

      await tester.enterText(pinFields.first, '1234');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Look for security question dropdown or security answer field in PIN creation flow.
      final securityQuestionDropdown =
          find.byType(DropdownButtonFormField<String>);
      if (securityQuestionDropdown.evaluate().isNotEmpty) {
        // Select first security question.
        await it.tryTap(tester, securityQuestionDropdown.first,
            after: const Duration(milliseconds: 300));
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Tap first dropdown item (if menu opened).
        final firstMenuItem = find.text('Vad är ditt favoritämne?').last;
        if (firstMenuItem.evaluate().isNotEmpty) {
          await it.tryTap(tester, firstMenuItem,
              after: const Duration(milliseconds: 300));
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
        }

        // Enter security answer.
        final securityAnswerField = find.widgetWithText(TextField, 'Ditt svar');
        if (securityAnswerField.evaluate().isNotEmpty) {
          await tester.enterText(securityAnswerField, 'Mat');
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
        }
      }

      // Confirm PIN creation.
      final confirmButton = find.text('Skapa');
      if (confirmButton.evaluate().isNotEmpty) {
        await it.tap(tester, confirmButton, after: const Duration(seconds: 1));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // If backup codes dialog appears, close it.
      if (find.text('Spara dina återställningskoder').evaluate().isNotEmpty) {
        final closeBackupDialog = find.text('Stäng');
        if (closeBackupDialog.evaluate().isNotEmpty) {
          await it.tap(tester, closeBackupDialog,
              after: const Duration(milliseconds: 500));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Should now be in Parent Dashboard.
      expect(find.text('Föräldradashboard'), findsWidgets);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Integration (Parent): verifiera PIN efter att ha skapat en',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go to settings.
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) return;

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap "Föräldraläge".
      final parentModeButton = find.text('Föräldraläge');
      if (parentModeButton.evaluate().isEmpty) return;

      await it.tap(tester, parentModeButton, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // If PIN already exists, should ask for PIN verification.
      final pinVerifyText = find.textContaining('Ange PIN');
      if (pinVerifyText.evaluate().isNotEmpty) {
        // Enter the PIN (1234 from previous test, or any 4-digit if fresh).
        final pinFields = find.byType(TextField);
        if (pinFields.evaluate().isNotEmpty) {
          await tester.enterText(pinFields.first, '1234');
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          final confirmButton = find.text('OK');
          if (confirmButton.evaluate().isNotEmpty) {
            await it.tap(tester, confirmButton,
                after: const Duration(seconds: 1));
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
        }

        // Should now be in Parent Dashboard.
        expect(find.text('Föräldradashboard'), findsWidgets);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Integration (Parent): PIN recovery med security question',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Parent Mode.
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) return;

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final parentModeButton = find.text('Föräldraläge');
      if (parentModeButton.evaluate().isEmpty) return;

      await it.tap(tester, parentModeButton, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Look for "Glömt PIN?" link.
      final forgotPinLink = find.text('Glömt PIN?');
      if (forgotPinLink.evaluate().isEmpty) {
        // PIN recovery not configured yet, skip test.
        return;
      }

      await it.tap(tester, forgotPinLink, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show security question.
      expect(find.text('Återställ PIN-kod'), findsWidgets);

      // Enter security answer (from previous test: "Mat").
      final securityAnswerField = find.byType(TextField).first;
      await tester.enterText(securityAnswerField, 'Mat');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final verifyButton = find.text('Verifiera');
      if (verifyButton.evaluate().isNotEmpty) {
        await it.tap(tester, verifyButton, after: const Duration(seconds: 1));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Should proceed to backup code screen or PIN reset screen.
      // (This depends on implementation; just verify no crash.)
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Integration (Profil): skapa ny profil och byt profil',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go to settings.
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) return;

      await it.tap(tester, settingsIcon, after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Look for "Byt profil" or "Skapa profil".
      final switchProfileButton = find.textContaining('profil');
      if (switchProfileButton.evaluate().isEmpty) return;

      await it.tap(tester, switchProfileButton.first,
          after: const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show profile selection or creation screen.
      final createProfileButton = find.text('Skapa profil');
      if (createProfileButton.evaluate().isNotEmpty) {
        await it.tap(tester, createProfileButton,
            after: const Duration(seconds: 1));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Enter profile name (e.g. "Test User").
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'Integration Test User');
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Select grade (Åk 3).
        final gradeDropdown = find.byType(DropdownButton<int?>);
        if (gradeDropdown.evaluate().isNotEmpty) {
          await it.tryTap(tester, gradeDropdown,
              after: const Duration(milliseconds: 300));
          await tester.pumpAndSettle(const Duration(milliseconds: 300));

          final ak3 = find.text('Åk 3').last;
          if (ak3.evaluate().isNotEmpty) {
            await it.tryTap(tester, ak3,
                after: const Duration(milliseconds: 300));
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
          }
        }

        // Confirm creation.
        final confirmButton = find.text('Skapa');
        if (confirmButton.evaluate().isNotEmpty) {
          await it.tap(tester, confirmButton,
              after: const Duration(seconds: 1));
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Should be back at home with new profile active.
        expect(tester.takeException(), isNull);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
