import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_game_app/main.dart' as app;
import 'package:math_game_app/presentation/widgets/answer_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QA tap count: key flows', (tester) async {
    final debugLogs = Platform.environment['TAP_COUNT_DEBUG'] == '1';
    var taps = 0;

    Finder _preferTappable(Finder finder) {
      // When a Finder targets a Text/Icon inside a button, tapping the leaf can
      // miss hit-testing depending on layout/overlays. Prefer tapping the
      // nearest tappable ancestor.
      final base = finder.first;

      final candidates = <Finder>[
        find.ancestor(of: base, matching: find.byType(IconButton)),
        find.ancestor(of: base, matching: find.byType(ElevatedButton)),
        find.ancestor(of: base, matching: find.byType(FilledButton)),
        find.ancestor(of: base, matching: find.byType(OutlinedButton)),
        find.ancestor(of: base, matching: find.byType(TextButton)),
        find.ancestor(of: base, matching: find.byType(InkWell)),
        find.ancestor(of: base, matching: find.byType(InkResponse)),
        find.ancestor(of: base, matching: find.byType(GestureDetector)),
        find.ancestor(of: base, matching: find.byType(ListTile)),
      ];

      for (final candidate in candidates) {
        if (candidate.evaluate().isNotEmpty) return candidate;
      }
      return finder;
    }

    Future<void> settle(
        [Duration duration = const Duration(milliseconds: 700)]) async {
      await tester.pumpAndSettle(duration);
    }

    Future<void> tap(Finder finder,
        {Duration settle = const Duration(milliseconds: 600)}) async {
      expect(finder, findsWidgets);
      final tappable = _preferTappable(finder);
      await tester.ensureVisible(tappable.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      taps++;
      await tester.tap(tappable.first);
      await tester.pumpAndSettle(settle);
    }

    Future<void> ensureOnboardingVisible() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        if (find.text('Kom igång').evaluate().isNotEmpty) return;
        await settle(const Duration(milliseconds: 600));
      }
      fail(
          'Onboarding did not appear. Visible texts: ${_visibleTexts(tester).take(80).toList()}');
    }

    Future<void> ensureHomeByVersionText() async {
      // Home has a version footer like "Version 1.0.0".
      for (var attempt = 0; attempt < 30; attempt++) {
        if (find.textContaining('Version ').evaluate().isNotEmpty) return;
        await settle(const Duration(milliseconds: 600));
      }
      fail(
          'Did not return to Home. Visible texts: ${_visibleTexts(tester).take(80).toList()}');
    }

    Future<void> startFirstAvailableQuiz() async {
      const operationLabels = <String>[
        'Addition',
        'Subtraktion',
        'Multiplikation',
        'Division',
      ];

      Finder? chosenOperation;
      for (final label in operationLabels) {
        final candidate = find.text(label);
        if (candidate.evaluate().isNotEmpty) {
          chosenOperation = candidate;
          break;
        }
      }

      if (chosenOperation == null) {
        fail(
            'No operation cards on Home. Visible texts: ${_visibleTexts(tester).take(80).toList()}');
      }

      await tap(chosenOperation, settle: const Duration(seconds: 1));
      expect(find.textContaining('Fråga '), findsOneWidget);
    }

    Future<void> answerAllQuestionsInSession() async {
      // Each question: 1 tap on an AnswerButton + 1 tap on "Fortsätt".
      for (var i = 0; i < 20; i++) {
        if (find.byType(AnswerButton).evaluate().isEmpty) {
          // If a feedback dialog is still open, dismiss it first.
          if (find.byType(Dialog).evaluate().isNotEmpty &&
              find.text('Fortsätt').evaluate().isNotEmpty) {
            await tap(find.text('Fortsätt'),
                settle: const Duration(milliseconds: 500));
            if (find.text('Tillbaka till Start').evaluate().isNotEmpty) return;
            continue;
          }

          // Likely already on Results.
          return;
        }

        await tap(find.byType(AnswerButton),
            settle: const Duration(milliseconds: 400));

        // Feedback dialog appears.
        await tap(find.text('Fortsätt'),
            settle: const Duration(milliseconds: 500));

        if (find.text('Resultat').evaluate().isNotEmpty) return;
        if (find.text('Tillbaka till Start').evaluate().isNotEmpty) return;
      }

      // After enough iterations, we should have finished.
      expect(find.text('Tillbaka till Start').evaluate().isNotEmpty, isTrue,
          reason: 'Expected to end on Results after answering all questions.');
    }

    // --- Scenario: first-time user (fresh app data expected) ---
    if (debugLogs) {
      // ignore: avoid_print
      print('TAP_COUNT_DEBUG: calling app.main()');
    }
    await app.main();
    if (debugLogs) {
      // ignore: avoid_print
      print('TAP_COUNT_DEBUG: app.main() returned');
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));
    if (debugLogs) {
      // ignore: avoid_print
      print(
        'TAP_COUNT_DEBUG: after pumpAndSettle: '
        'Text=${find.byType(Text).evaluate().length} '
        'Scaffold=${find.byType(Scaffold).evaluate().length} '
        'MaterialApp=${find.byType(MaterialApp).evaluate().length}',
      );
      // ignore: avoid_print
      final debugTexts =
          tester.widgetList<Text>(find.byType(Text)).take(10).map(
                (t) => {
                  'data': t.data,
                  'span': t.textSpan?.toPlainText(),
                  'runtime': t.toStringShort(),
                },
              );
      // ignore: avoid_print
      print('TAP_COUNT_DEBUG: first Text widgets: ${debugTexts.toList()}');

      // ignore: avoid_print
      print(
        'TAP_COUNT_DEBUG: pre home check: '
        'Skapa=${find.text('Skapa användare').evaluate().length} '
        'Addition=${find.text('Addition').evaluate().length}',
      );
    }

    await settle();

    final createUserButtonText = find.text('Skapa användare');
    final createUserHomeButton = find.ancestor(
      of: createUserButtonText,
      matching: find.byType(ElevatedButton),
    );

    if (createUserHomeButton.evaluate().isNotEmpty) {
      final tapsBefore = taps;

      // 1) Home -> open create dialog
      await tap(createUserHomeButton);

      // 2) Create user (name input not counted)
      expect(find.text('Skapa användare'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'QA');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Optional grade selection: pick Åk 3 to trigger onboarding skip.
      // Tap dropdown, then select "Åk 3".
      final gradeDropdown = find.byType(DropdownButton<int?>);
      if (gradeDropdown.evaluate().isNotEmpty) {
        await tap(gradeDropdown, settle: const Duration(milliseconds: 400));
        await tap(find.text('Åk 3'), settle: const Duration(milliseconds: 400));
      }

      await tap(find.text('Skapa'), settle: const Duration(seconds: 1));

      // Wait for onboarding pushed from Home.
      await ensureOnboardingVisible();

      // Onboarding: since grade already set, should start at "Välj räknesätt".
      // We accept defaults and press Next then Klar.
      if (find.text('Välj årskurs').evaluate().isNotEmpty) {
        // If grade step still shown, select Åk 3 there as well.
        final gradeDropdown2 = find.byType(DropdownButton<int?>);
        if (gradeDropdown2.evaluate().isNotEmpty) {
          await tap(gradeDropdown2, settle: const Duration(milliseconds: 400));
          await tap(find.text('Åk 3'),
              settle: const Duration(milliseconds: 400));
        }
        await tap(find.text('Nästa'),
            settle: const Duration(milliseconds: 700));
      }

      // Ops page
      expect(find.text('Välj räknesätt').evaluate().isNotEmpty, isTrue,
          reason:
              'Expected ops onboarding step. Visible texts: ${_visibleTexts(tester).take(40).toList()}');
      await tap(find.text('Klar'), settle: const Duration(seconds: 1));

      await settle(const Duration(seconds: 1));

      final tapsCreateAndOnboarding = taps - tapsBefore;

      // Parent mode tap count (from Home): set a new PIN, then reopen with existing.
      // Text entry is not counted.
      int? tapsParentFlow;
      final lockButtonOnHome = find.byIcon(Icons.lock);
      if (lockButtonOnHome.evaluate().isNotEmpty) {
        final tapsBeforeParent = taps;

        // First open -> create PIN
        await tap(lockButtonOnHome, settle: const Duration(milliseconds: 800));
        await tester.enterText(find.widgetWithText(TextField, 'PIN'), '1234');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        final confirmField = find.widgetWithText(TextField, 'Bekräfta PIN');
        if (confirmField.evaluate().isNotEmpty) {
          await tester.enterText(confirmField, '1234');
          await tester.pumpAndSettle(const Duration(milliseconds: 200));
        }
        if (find.text('Spara PIN').evaluate().isNotEmpty) {
          await tap(find.text('Spara PIN'), settle: const Duration(seconds: 1));
        } else {
          await tap(find.text('Öppna'), settle: const Duration(seconds: 1));
        }

        // Back to Home (not counted)
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
        await settle(const Duration(seconds: 1));

        // Second open -> existing PIN
        await tap(lockButtonOnHome, settle: const Duration(milliseconds: 800));
        await tester.enterText(find.widgetWithText(TextField, 'PIN'), '1234');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        await tap(find.text('Öppna'), settle: const Duration(seconds: 1));

        // Back to Home again (not counted)
        await tester.pageBack();
        await settle(const Duration(seconds: 1));
        await ensureHomeByVersionText();

        tapsParentFlow = taps - tapsBeforeParent;
      }

      // Start first quiz
      final tapsBeforeQuizStart = taps;
      await startFirstAvailableQuiz();
      final tapsToFirstQuestion =
          tapsCreateAndOnboarding + (taps - tapsBeforeQuizStart);

      // Finish session -> results -> start next recommended session.
      final tapsBeforeSession = taps;
      await answerAllQuestionsInSession();

      // On Results, tap recommended "Öva på det svåraste (2 min)".
      const practiceLabel = 'Öva på det svåraste (2 min)';
      final practiceButton = find.widgetWithText(ElevatedButton, practiceLabel);

      if (practiceButton.evaluate().isNotEmpty ||
          find.text(practiceLabel).evaluate().isNotEmpty) {
        await tap(
            practiceButton.evaluate().isNotEmpty
                ? practiceButton
                : find.text(practiceLabel),
            settle: const Duration(seconds: 1));
        expect(find.textContaining('Fråga '), findsOneWidget);
      }

      final tapsToFinishAndStartNext = taps - tapsBeforeSession;

      // Close quiz (back to Results).
      await tap(find.byIcon(Icons.close), settle: const Duration(seconds: 1));
      await settle(const Duration(seconds: 1));

      // Print verified counts.
      // NOTE: These are meant to be copied into FÖRBÄTTRINGAR.md.
      // ignore: avoid_print
      print('TAP_COUNT_FIRST_TIME_to_first_question=$tapsToFirstQuestion');
      // ignore: avoid_print
      print(
          'TAP_COUNT_FIRST_TIME_finish_session_and_start_next=$tapsToFinishAndStartNext');
      // ignore: avoid_print
      print(
        'TAP_COUNT_PARENT_set_and_reopen_existing='
        '${tapsParentFlow ?? 'NA'}',
      );
    } else {
      fail(
          'Expected fresh install ("Skapa användare" visible). Clear app data before running this test.');
    }

    // Basic per-question verification from the executed session:
    // ignore: avoid_print
    print('TAP_COUNT_PER_QUESTION_expected=2 (answer + Fortsätt)');
  });
}

List<String> _visibleTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? w.textSpan?.toPlainText())
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}
