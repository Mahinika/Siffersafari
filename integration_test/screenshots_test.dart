import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siffersafari/main.dart' as app;
import 'package:siffersafari/presentation/widgets/answer_button.dart';

import 'test_utils.dart' as it;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integration (screenshots): ta skärmdumpar av alla huvudvyer',
    (tester) async {
      Future<void> waitFor(
        String label,
        bool Function() condition, {
        Duration timeout = const Duration(seconds: 20),
        Duration step = const Duration(milliseconds: 600),
      }) async {
        final sw = Stopwatch()..start();
        while (sw.elapsed < timeout) {
          if (condition()) return;
          await it.settle(tester, step);
        }

        fail(
          'Timed out waiting for: $label. Visible texts: ${it.visibleTexts(tester).take(80).toList()}',
        );
      }

      Future<void> settle([
        Duration duration = const Duration(milliseconds: 800),
      ]) async {
        await it.settle(tester, duration);
      }

      bool isHomeLike() {
        // Home has a version footer like "Version 1.0.0".
        if (find.textContaining('Version ').evaluate().isNotEmpty) return true;

        // Landing / first-run screens.
        if (find.textContaining('Välkommen').evaluate().isNotEmpty) return true;
        if (find.text('Siffersafari').evaluate().isNotEmpty) return true;
        if (find.text('Skapa profil').evaluate().isNotEmpty) return true;
        if (find.text('Skapa användare').evaluate().isNotEmpty) return true;

        // Logged-in Home with operation cards.
        for (final label in const [
          'Addition',
          'Subtraktion',
          'Multiplikation',
          'Division',
        ]) {
          if (find.text(label).evaluate().isNotEmpty) return true;
        }

        return false;
      }

      String safeName(String raw) {
        final cleaned = raw
            .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_')
            .replaceAll(RegExp(r'_{2,}'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');
        return cleaned.isEmpty ? 'shot' : cleaned;
      }

      var screenshotIndex = 1;
      Future<void> shot(String label) async {
        final index = screenshotIndex.toString().padLeft(2, '0');
        screenshotIndex++;

        // Give the UI a moment to settle before capturing.
        await settle(const Duration(milliseconds: 700));

        // Using INTEGRATION_TEST_SHOT_ARGS allows future host-side extraction.
        await binding.takeScreenshot('${index}_${safeName(label)}');
      }

      Future<void> ensureHomeVisible() async {
        await waitFor(
          'Home / start screen / onboarding gate',
          () {
            if (isHomeLike()) return true;

            // If onboarding blocks, that's acceptable as "home is visible enough".
            if (find.text('Kom igång').evaluate().isNotEmpty) return true;
            if (find.text('Hoppa över').evaluate().isNotEmpty) return true;
            if (find.textContaining('Vilken årskurs').evaluate().isNotEmpty) {
              return true;
            }
            if (find.text('Årskurs').evaluate().isNotEmpty) return true;
            if (find.text('Välj årskurs').evaluate().isNotEmpty) return true;
            if (find.text('Välj räknesätt').evaluate().isNotEmpty) return true;

            return false;
          },
          timeout: const Duration(seconds: 20),
          step: const Duration(milliseconds: 600),
        );
      }

      Future<void> backOnce() async {
        await it.backOnce(tester);
      }

      Future<void> backUntilHome({int maxBacks = 8}) async {
        for (var i = 0; i < maxBacks; i++) {
          if (isHomeLike()) return;
          await backOnce();
        }
      }

      Future<void> ensureOnboardingVisible() async {
        await waitFor(
          'Onboarding',
          () {
            if (find.text('Kom igång').evaluate().isNotEmpty) return true;
            if (find.text('Hoppa över').evaluate().isNotEmpty) return true;
            if (find.textContaining('Vilken årskurs').evaluate().isNotEmpty) {
              return true;
            }
            if (find.text('Årskurs').evaluate().isNotEmpty) return true;
            if (find.text('Välj årskurs').evaluate().isNotEmpty) return true;
            if (find.text('Välj räknesätt').evaluate().isNotEmpty) return true;

            // Step indicator like "1/2" or "1/3".
            final stepIndicators = ['1/2', '1/3', '2/3'];
            for (final s in stepIndicators) {
              if (find.text(s).evaluate().isNotEmpty) return true;
            }

            return false;
          },
          timeout: const Duration(seconds: 15),
          step: const Duration(milliseconds: 600),
        );
      }

      Future<void> ensureResultsVisible() async {
        await waitFor(
          'Results (Tillbaka till Start)',
          () => find.text('Tillbaka till Start').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 25),
          step: const Duration(milliseconds: 500),
        );
      }

      // ---- Boot ----
      await app.main();

      // App startup does async init (Hive + DI).
      await it.settle(tester, const Duration(seconds: 3));

      // Required for Android screenshots.
      await binding.convertFlutterSurfaceToImage();
      await settle(const Duration(milliseconds: 900));

      await ensureHomeVisible();

      // ---- Initial state: Home / no-user flows ----
      await shot('home_initial');

      final createUserButton =
          find.widgetWithText(ElevatedButton, 'Skapa profil');
      final createUserButtonFallback =
          find.widgetWithText(ElevatedButton, 'Skapa användare');
      final createProfileButton = createUserButton.evaluate().isNotEmpty
          ? createUserButton
          : createUserButtonFallback;
      if (createProfileButton.evaluate().isNotEmpty) {
        // Open Settings via the "no user" path (start quiz -> redirected).
        Finder? opOnHome;
        for (final label in const [
          'Addition',
          'Subtraktion',
          'Multiplikation',
          'Division',
        ]) {
          final candidate = find.text(label);
          if (candidate.evaluate().isNotEmpty) {
            opOnHome = candidate;
            break;
          }
        }
        if (opOnHome != null) {
          await it.tap(tester, opOnHome);
          if (find.text('Inställningar').evaluate().isNotEmpty) {
            await shot('settings_no_user');
            await backOnce();
            await ensureHomeVisible();
          }
        }

        await shot('home_no_user');

        // Create user dialog.
        await it.tap(tester, createProfileButton);
        expect(
          find.byType(TextField).evaluate().isNotEmpty,
          isTrue,
          reason:
              'Expected a create profile dialog. Visible texts: ${it.visibleTexts(tester).take(80).toList()}',
        );
        await shot('create_user_dialog');

        await tester.enterText(find.byType(TextField).first, 'UI TEST 1');
        await settle(const Duration(milliseconds: 400));
        await shot('create_user_dialog_name_filled');

        await it.tap(
          tester,
          find.text('Skapa'),
          after: const Duration(seconds: 2),
        );

        // Onboarding is pushed after returning to Home.
        await ensureOnboardingVisible();

        // ---- Onboarding step 1: grade ----
        await shot('onboarding_grade');

        final isGradePage =
            find.textContaining('årskurs').evaluate().isNotEmpty ||
                find.text('Årskurs').evaluate().isNotEmpty ||
                find.text('Välj årskurs').evaluate().isNotEmpty ||
                find.text('1/2').evaluate().isNotEmpty ||
                find.text('1/3').evaluate().isNotEmpty;
        if (isGradePage) {
          final gradeDropdown = find.byType(DropdownButton<int?>);
          if (gradeDropdown.evaluate().isNotEmpty) {
            final opened = await it.tryTap(
              tester,
              gradeDropdown.first,
              after: const Duration(milliseconds: 600),
            );
            if (opened) {
              await shot('onboarding_grade_dropdown_open');
              if (find.text('Åk 3').evaluate().isNotEmpty) {
                await it.tryTap(
                  tester,
                  find.text('Åk 3'),
                  after: const Duration(milliseconds: 700),
                );
                await shot('onboarding_grade_selected');
              } else {
                // Close dropdown by tapping "Ingen" if present.
                if (find.text('Ingen').evaluate().isNotEmpty) {
                  await it.tryTap(
                    tester,
                    find.text('Ingen'),
                    after: const Duration(milliseconds: 600),
                  );
                }
              }
            }
          }
        }

        if (find.text('Nästa').evaluate().isNotEmpty) {
          await it.tap(
            tester,
            find.text('Nästa'),
            after: const Duration(seconds: 1),
          );
        }

        // ---- Onboarding step 2: operations ----
        if (find.text('Välj räknesätt').evaluate().isNotEmpty) {
          await shot('onboarding_ops');

          // Select all operations (CheckboxListTile toggles).
          for (final label in const ['Addition', 'Subtraktion', 'Division']) {
            if (find.text(label).evaluate().isNotEmpty) {
              // Tap twice defensively only if it would turn it off; we just tap once here.
              await it.tap(
                tester,
                find.text(label),
                after: const Duration(milliseconds: 350),
              );
            }
          }

          await shot('onboarding_ops_toggled');
        }

        if (find.text('Klar').evaluate().isNotEmpty) {
          await it.tap(
            tester,
            find.text('Klar'),
            after: const Duration(seconds: 1),
          );
        }

        await ensureHomeVisible();
        await shot('home_with_user');
      } else {
        // Existing user state.
        await shot('home_existing_user');
      }

      // ---- Parent mode ----
      final lockButton = find.byIcon(Icons.lock);
      if (lockButton.evaluate().isNotEmpty) {
        await it.tap(
          tester,
          lockButton,
          after: const Duration(milliseconds: 900),
        );
        await shot('parent_pin');

        // Create or enter PIN.
        if (find.widgetWithText(TextField, 'PIN').evaluate().isNotEmpty) {
          await tester.enterText(
            find.widgetWithText(TextField, 'PIN').first,
            '1234',
          );
          await settle(const Duration(milliseconds: 250));
        }
        final confirmField = find.widgetWithText(TextField, 'Bekräfta PIN');
        if (confirmField.evaluate().isNotEmpty) {
          await tester.enterText(confirmField.first, '1234');
          await settle(const Duration(milliseconds: 250));
        }
        await shot('parent_pin_filled');

        if (find.text('Spara PIN').evaluate().isNotEmpty) {
          await it.tap(
            tester,
            find.text('Spara PIN'),
            after: const Duration(seconds: 1),
          );
        } else if (find.text('Öppna').evaluate().isNotEmpty) {
          await it.tap(
            tester,
            find.text('Öppna'),
            after: const Duration(seconds: 1),
          );
        }

        if (find.text('Föräldraläge').evaluate().isNotEmpty) {
          await shot('parent_dashboard_overview');

          // Capture each section by scrolling to anchors.
          for (final anchor in const [
            'Anpassningar',
            'Analys',
            'Senaste quiz',
          ]) {
            final anchorFinder = find.text(anchor);
            if (anchorFinder.evaluate().isNotEmpty) {
              await tester.ensureVisible(anchorFinder.first);
              await settle(const Duration(milliseconds: 700));
              await shot(
                'parent_dashboard_${anchor.toLowerCase().replaceAll(' ', '_')}',
              );
            }
          }

          // Open Settings from parent dashboard.
          final settingsIcon = find.byIcon(Icons.settings);
          if (settingsIcon.evaluate().isNotEmpty) {
            await it.tap(
              tester,
              settingsIcon,
              after: const Duration(seconds: 1),
            );
            if (find.text('Inställningar').evaluate().isNotEmpty) {
              await shot('settings_from_parent');

              // Open grade dropdown (if user exists) to capture menu.
              final gradeDrop2 = find.byType(DropdownButton<int?>);
              if (gradeDrop2.evaluate().isNotEmpty) {
                await it.tap(
                  tester,
                  gradeDrop2.first,
                  after: const Duration(milliseconds: 700),
                );
                await shot('settings_grade_dropdown_open');
                // Choose a specific value to close the menu.
                if (find.text('Åk 3').evaluate().isNotEmpty) {
                  await it.tap(
                    tester,
                    find.text('Åk 3'),
                    after: const Duration(milliseconds: 700),
                  );
                } else if (find.text('Ingen').evaluate().isNotEmpty) {
                  await it.tap(
                    tester,
                    find.text('Ingen'),
                    after: const Duration(milliseconds: 700),
                  );
                }
              }

              // Toggle switches if present.
              for (final label in const ['Ljudeffekter', 'Musik']) {
                final tile = find.text(label);
                if (tile.evaluate().isNotEmpty) {
                  await it.tap(
                    tester,
                    tile,
                    after: const Duration(milliseconds: 500),
                  );
                }
              }
              await shot('settings_after_toggles');

              // Open create user dialog from Settings.
              final createFromSettings =
                  find.text('Skapa användare').evaluate().isNotEmpty
                      ? find.text('Skapa användare')
                      : find.text('Skapa profil');
              if (createFromSettings.evaluate().isNotEmpty) {
                await it.tap(
                  tester,
                  createFromSettings,
                  after: const Duration(milliseconds: 600),
                );
                if (find.byType(TextField).evaluate().isNotEmpty) {
                  await shot('settings_create_user_dialog');

                  if (find.text('Avbryt').evaluate().isNotEmpty) {
                    await it.tap(
                      tester,
                      find.text('Avbryt'),
                      after: const Duration(milliseconds: 600),
                    );
                  } else {
                    await backOnce();
                  }
                }
              }

              await backOnce();
            }
          }

          // Open change PIN flow.
          final keyIcon = find.byIcon(Icons.key);
          if (keyIcon.evaluate().isNotEmpty) {
            await it.tap(
              tester,
              keyIcon,
              after: const Duration(milliseconds: 900),
            );
            await shot('parent_pin_change');
            if (find.widgetWithText(TextField, 'PIN').evaluate().isNotEmpty) {
              await tester.enterText(
                find.widgetWithText(TextField, 'PIN').first,
                '4321',
              );
              await settle(const Duration(milliseconds: 250));
            }
            final confirmField2 =
                find.widgetWithText(TextField, 'Bekräfta PIN');
            if (confirmField2.evaluate().isNotEmpty) {
              await tester.enterText(confirmField2.first, '4321');
              await settle(const Duration(milliseconds: 250));
            }
            await shot('parent_pin_change_filled');
            if (find.text('Spara PIN').evaluate().isNotEmpty) {
              await it.tap(
                tester,
                find.text('Spara PIN'),
                after: const Duration(seconds: 1),
              );
            } else {
              await backOnce();
            }
          }

          // Back to Home.
          await backUntilHome();
          await shot('home_after_parent');
        }
      }

      // ---- Quiz + feedback + results ----
      const operationLabels = [
        'Addition',
        'Subtraktion',
        'Multiplikation',
        'Division',
      ];
      Finder? chosenOperation;
      for (final label in operationLabels) {
        final f = find.text(label);
        if (f.evaluate().isNotEmpty) {
          chosenOperation = f;
          break;
        }
      }

      if (chosenOperation != null) {
        await it.tap(
          tester,
          chosenOperation,
          after: const Duration(seconds: 1),
        );
        if (find.textContaining('Fråga ').evaluate().isNotEmpty) {
          await shot('quiz_question_1');

          // Answer first question to show feedback dialog.
          if (find.byType(AnswerButton).evaluate().isNotEmpty) {
            await it.tap(
              tester,
              find.byType(AnswerButton).first,
              after: const Duration(milliseconds: 600),
            );
          }

          if (find.text('Fortsätt').evaluate().isNotEmpty) {
            await shot('quiz_feedback_dialog');
            await it.tap(
              tester,
              find.text('Fortsätt'),
              after: const Duration(milliseconds: 700),
            );
            await shot('quiz_question_2');
          }

          // Finish the session quickly to reach Results.
          for (var i = 0; i < 40; i++) {
            if (find.text('Tillbaka till Start').evaluate().isNotEmpty) break;

            if (find.byType(AnswerButton).evaluate().isNotEmpty) {
              await it.tap(
                tester,
                find.byType(AnswerButton).first,
                after: const Duration(milliseconds: 350),
              );
            }

            if (find.text('Fortsätt').evaluate().isNotEmpty) {
              await it.tap(
                tester,
                find.text('Fortsätt'),
                after: const Duration(milliseconds: 450),
              );
            }
          }

          await ensureResultsVisible();
          await shot('results_top');

          // Scroll to bottom buttons.
          final backToStart = find.text('Tillbaka till Start');
          if (backToStart.evaluate().isNotEmpty) {
            await tester.ensureVisible(backToStart.first);
            await settle(const Duration(milliseconds: 700));
            await shot('results_bottom');
            await it.tap(
              tester,
              backToStart,
              after: const Duration(seconds: 1),
            );
          }

          await ensureHomeVisible();
          await shot('home_after_results');
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
