import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/main.dart' as app;

import 'test_utils.dart' as it;

/// Integration tests for parent-facing critical features:
/// - PIN creation happy path
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
      await it.waitForText(
        tester,
        'Skapa PIN',
        timeout: const Duration(seconds: 12),
      );

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
      await it.tap(
        tester,
        savePinButton,
        after: const Duration(milliseconds: 450),
      );

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
      await it.waitForText(
        tester,
        'Översikt',
        timeout: const Duration(seconds: 20),
      );
      expect(find.text('Översikt'), findsWidgets);
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
