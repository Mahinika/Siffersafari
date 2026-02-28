import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_game_app/main.dart' as app;
import 'package:math_game_app/presentation/widgets/answer_button.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI TEST 1: screenshots (all major views)', (tester) async {
    Future<void> settle([
      Duration duration = const Duration(milliseconds: 800),
    ]) async {
      await tester.pumpAndSettle(duration);
    }

    Future<bool> tryTap(
      Finder finder, {
      Duration after = const Duration(milliseconds: 900),
      List<String>? errors,
    }) async {
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      final candidates = <Finder>[
        // If the finder targets a leaf (Text/Icon), climb to common tappables.
        find.ancestor(of: finder, matching: find.byType(IconButton)),
        find.ancestor(of: finder, matching: find.byType(ElevatedButton)),
        find.ancestor(of: finder, matching: find.byType(FilledButton)),
        find.ancestor(of: finder, matching: find.byType(OutlinedButton)),
        find.ancestor(of: finder, matching: find.byType(TextButton)),
        find.ancestor(of: finder, matching: find.byType(ListTile)),

        // If the finder targets a composite (e.g. ElevatedButton/DropdownButton),
        // tap on an internal render box that participates in hit testing.
        find.descendant(of: finder, matching: find.byType(InkResponse)),
        find.descendant(of: finder, matching: find.byType(InkWell)),
        find.descendant(of: finder, matching: find.byType(GestureDetector)),

        // Last resort.
        finder,
      ];

      for (final candidate in candidates) {
        bool hasMatch;
        try {
          hasMatch = candidate.evaluate().isNotEmpty;
        } catch (_) {
          continue;
        }
        if (!hasMatch) continue;

        final target = candidate.first;
        await tester.ensureVisible(target);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        try {
          await tester.tap(target);
          await tester.pumpAndSettle(after);
          return true;
        } catch (e) {
          errors?.add('${candidate.description}: $e');
          // Try next candidate.
        }
      }

      return false;
    }

    Future<void> tap(
      Finder finder, {
      Duration after = const Duration(milliseconds: 900),
    }) async {
      final errors = <String>[];
      final ok = await tryTap(
        finder,
        after: after,
        errors: errors,
      );
      if (ok) return;

      fail(
        'Tried to tap a widget, but no tappable RenderBox was found. Finder: ${finder.description}. Errors: $errors. Visible texts: ${_visibleTexts(tester).take(80).toList()}',
      );
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
      for (var attempt = 0; attempt < 40; attempt++) {
        // Home has a version footer like "Version 1.0.0".
        if (find.textContaining('Version ').evaluate().isNotEmpty) return;

        // If onboarding blocks, wait.
        if (find.text('Kom igång').evaluate().isNotEmpty) return;

        await settle(const Duration(milliseconds: 600));
      }

      fail(
        'Could not reach Home or Onboarding. Visible texts: ${_visibleTexts(tester).take(80).toList()}',
      );
    }

    Future<void> backOnce() async {
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await settle(const Duration(seconds: 1));
        return;
      }

      // Fallback.
      await tester.pageBack();
      await settle(const Duration(seconds: 1));
    }

    Future<void> backUntilHome({int maxBacks = 8}) async {
      for (var i = 0; i < maxBacks; i++) {
        if (find.textContaining('Version ').evaluate().isNotEmpty) return;
        await backOnce();
      }
    }

    Future<void> ensureOnboardingVisible() async {
      for (var attempt = 0; attempt < 40; attempt++) {
        if (find.text('Kom igång').evaluate().isNotEmpty) return;
        await settle(const Duration(milliseconds: 600));
      }
      fail(
        'Onboarding did not appear. Visible texts: ${_visibleTexts(tester).take(80).toList()}',
      );
    }

    Future<void> ensureResultsVisible() async {
      for (var attempt = 0; attempt < 80; attempt++) {
        if (find.text('Tillbaka till Start').evaluate().isNotEmpty) return;
        await settle(const Duration(milliseconds: 500));
      }
      fail(
        'Results did not appear. Visible texts: ${_visibleTexts(tester).take(80).toList()}',
      );
    }

    // ---- Boot ----
    await app.main();

    // App startup does async init (Hive + DI).
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Required for Android screenshots.
    await binding.convertFlutterSurfaceToImage();
    await settle(const Duration(milliseconds: 900));

    await ensureHomeVisible();

    // ---- Initial state: Home / no-user flows ----
    await shot('home_initial');

    final createUserButton =
        find.widgetWithText(ElevatedButton, 'Skapa användare');
    if (createUserButton.evaluate().isNotEmpty) {
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
        await tap(opOnHome);
        if (find.text('Inställningar').evaluate().isNotEmpty) {
          await shot('settings_no_user');
          await backOnce();
          await ensureHomeVisible();
        }
      }

      await shot('home_no_user');

      // Create user dialog.
      await tap(createUserButton);
      expect(find.text('Skapa användare'), findsWidgets);
      await shot('create_user_dialog');

      await tester.enterText(find.byType(TextField).first, 'UI TEST 1');
      await settle(const Duration(milliseconds: 400));
      await shot('create_user_dialog_name_filled');

      await tap(find.text('Skapa'), after: const Duration(seconds: 2));

      // Onboarding is pushed after returning to Home.
      await ensureOnboardingVisible();

      // ---- Onboarding step 1: grade ----
      await shot('onboarding_grade');

      final isGradePage = find.text('1/2').evaluate().isNotEmpty;
      if (isGradePage) {
        final gradeDropdown = find.byType(DropdownButton<int?>);
        if (gradeDropdown.evaluate().isNotEmpty) {
          final opened = await tryTap(
            gradeDropdown.first,
            after: const Duration(milliseconds: 600),
          );
          if (opened) {
            await shot('onboarding_grade_dropdown_open');
            if (find.text('Åk 3').evaluate().isNotEmpty) {
              await tryTap(
                find.text('Åk 3'),
                after: const Duration(milliseconds: 700),
              );
              await shot('onboarding_grade_selected');
            } else {
              // Close dropdown by tapping "Ingen" if present.
              if (find.text('Ingen').evaluate().isNotEmpty) {
                await tryTap(
                  find.text('Ingen'),
                  after: const Duration(milliseconds: 600),
                );
              }
            }
          }
        }
      }

      if (find.text('Nästa').evaluate().isNotEmpty) {
        await tap(find.text('Nästa'), after: const Duration(seconds: 1));
      }

      // ---- Onboarding step 2: operations ----
      if (find.text('Välj räknesätt').evaluate().isNotEmpty) {
        await shot('onboarding_ops');

        // Select all operations (CheckboxListTile toggles).
        for (final label in const ['Addition', 'Subtraktion', 'Division']) {
          if (find.text(label).evaluate().isNotEmpty) {
            // Tap twice defensively only if it would turn it off; we just tap once here.
            await tap(
              find.text(label),
              after: const Duration(milliseconds: 350),
            );
          }
        }

        await shot('onboarding_ops_toggled');
      }

      if (find.text('Klar').evaluate().isNotEmpty) {
        await tap(find.text('Klar'), after: const Duration(seconds: 1));
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
      await tap(lockButton, after: const Duration(milliseconds: 900));
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
        await tap(find.text('Spara PIN'), after: const Duration(seconds: 1));
      } else if (find.text('Öppna').evaluate().isNotEmpty) {
        await tap(find.text('Öppna'), after: const Duration(seconds: 1));
      }

      if (find.text('Föräldraläge').evaluate().isNotEmpty) {
        await shot('parent_dashboard_overview');

        // Capture each section by scrolling to anchors.
        for (final anchor in const ['Anpassningar', 'Analys', 'Senaste quiz']) {
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
          await tap(settingsIcon, after: const Duration(seconds: 1));
          if (find.text('Inställningar').evaluate().isNotEmpty) {
            await shot('settings_from_parent');

            // Open grade dropdown (if user exists) to capture menu.
            final gradeDrop2 = find.byType(DropdownButton<int?>);
            if (gradeDrop2.evaluate().isNotEmpty) {
              await tap(
                gradeDrop2.first,
                after: const Duration(milliseconds: 700),
              );
              await shot('settings_grade_dropdown_open');
              // Choose a specific value to close the menu.
              if (find.text('Åk 3').evaluate().isNotEmpty) {
                await tap(
                  find.text('Åk 3'),
                  after: const Duration(milliseconds: 700),
                );
              } else if (find.text('Ingen').evaluate().isNotEmpty) {
                await tap(
                  find.text('Ingen'),
                  after: const Duration(milliseconds: 700),
                );
              }
            }

            // Toggle switches if present.
            for (final label in const ['Ljudeffekter', 'Musik']) {
              final tile = find.text(label);
              if (tile.evaluate().isNotEmpty) {
                await tap(tile, after: const Duration(milliseconds: 500));
              }
            }
            await shot('settings_after_toggles');

            // Open create user dialog from Settings.
            if (find.text('Skapa användare').evaluate().isNotEmpty) {
              await tap(
                find.text('Skapa användare'),
                after: const Duration(milliseconds: 600),
              );
              if (find.text('Skapa användare').evaluate().length >= 2) {
                await shot('settings_create_user_dialog');

                if (find.text('Avbryt').evaluate().isNotEmpty) {
                  await tap(
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
          await tap(keyIcon, after: const Duration(milliseconds: 900));
          await shot('parent_pin_change');
          if (find.widgetWithText(TextField, 'PIN').evaluate().isNotEmpty) {
            await tester.enterText(
              find.widgetWithText(TextField, 'PIN').first,
              '4321',
            );
            await settle(const Duration(milliseconds: 250));
          }
          final confirmField2 = find.widgetWithText(TextField, 'Bekräfta PIN');
          if (confirmField2.evaluate().isNotEmpty) {
            await tester.enterText(confirmField2.first, '4321');
            await settle(const Duration(milliseconds: 250));
          }
          await shot('parent_pin_change_filled');
          if (find.text('Spara PIN').evaluate().isNotEmpty) {
            await tap(
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
      await tap(chosenOperation, after: const Duration(seconds: 1));
      if (find.textContaining('Fråga ').evaluate().isNotEmpty) {
        await shot('quiz_question_1');

        // Answer first question to show feedback dialog.
        if (find.byType(AnswerButton).evaluate().isNotEmpty) {
          await tap(
            find.byType(AnswerButton).first,
            after: const Duration(milliseconds: 600),
          );
        }

        if (find.text('Fortsätt').evaluate().isNotEmpty) {
          await shot('quiz_feedback_dialog');
          await tap(
            find.text('Fortsätt'),
            after: const Duration(milliseconds: 700),
          );
          await shot('quiz_question_2');
        }

        // Finish the session quickly to reach Results.
        for (var i = 0; i < 40; i++) {
          if (find.text('Tillbaka till Start').evaluate().isNotEmpty) break;

          if (find.byType(AnswerButton).evaluate().isNotEmpty) {
            await tap(
              find.byType(AnswerButton).first,
              after: const Duration(milliseconds: 350),
            );
          }

          if (find.text('Fortsätt').evaluate().isNotEmpty) {
            await tap(
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
          await tap(backToStart, after: const Duration(seconds: 1));
        }

        await ensureHomeVisible();
        await shot('home_after_results');
      }
    }
  });
}

List<String> _visibleTexts(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data)
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  texts.sort();
  return texts;
}
