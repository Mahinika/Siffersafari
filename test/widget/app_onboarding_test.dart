import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/constants/app_constants.dart';
import 'package:math_game_app/domain/entities/user_progress.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/main.dart';
import '../test_utils.dart';

void main() {
  late InMemoryLocalStorageRepository repository;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    repository = await setupWidgetTestDependencies();
  });

  testWidgets(
    '[Widget] Onboarding – shown once and does not repeat',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
        gradeLevel: 3,
      );
      await repository.saveUserProgress(user);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final onboardingTitle = find.text('Nu kör vi!');
      final steps = (const Duration(seconds: 4).inMilliseconds / 50).ceil();
      for (var i = 0; i < steps; i++) {
        if (onboardingTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Nu kör vi!'), findsOneWidget);

      await tester.tap(find.text('Hoppa över'));
      await pumpUntilFound(tester, find.text(AppConstants.appName));

      // Onboarding should not appear again after skipping
      expect(find.text('Nu kör vi!'), findsNothing);
    },
  );

  testWidgets(
    '[Widget] Onboarding – Done button does not return to step 1',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final onboardingTitle = find.text('Nu kör vi!');
      final steps = (const Duration(seconds: 4).inMilliseconds / 50).ceil();
      for (var i = 0; i < steps; i++) {
        if (onboardingTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(onboardingTitle, findsOneWidget);
      final hasReadingStep = find.text('1/3').evaluate().isNotEmpty;
      expect(find.text(hasReadingStep ? '1/3' : '1/2'), findsOneWidget);
      expect(find.text('Vilken årskurs kör du?'), findsOneWidget);

      final gradeDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButton<int?>,
      );
      expect(gradeDropdown, findsOneWidget);
      await tester.tap(gradeDropdown);
      await pumpFor(tester, const Duration(milliseconds: 200));
      await tester.tap(find.text('Åk 3').last);
      await pumpFor(tester, const Duration(milliseconds: 200));

      await tester.tap(find.text('Nästa'));
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 200),
      );

      if (hasReadingStep) {
        expect(find.text('2/3'), findsOneWidget);
        expect(find.text('Kan barnet läsa?'), findsOneWidget);

        await tester.tap(find.text('Nej'));
        await pumpFor(
          tester,
          AppConstants.mediumAnimationDuration +
              const Duration(milliseconds: 200),
        );

        expect(find.text('3/3'), findsOneWidget);
      } else {
        expect(find.text('2/2'), findsOneWidget);
      }

      expect(find.text('Vad vill du räkna?'), findsOneWidget);

      await tester.tap(find.text('Klar'));

      final homeTitle = find.text(AppConstants.appName);
      final finishSteps =
          (const Duration(seconds: 4).inMilliseconds / 50).ceil();
      for (var i = 0; i < finishSteps; i++) {
        if (homeTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }

      await pumpFor(tester, const Duration(milliseconds: 600));

      expect(homeTitle, findsOneWidget);
      expect(onboardingTitle, findsNothing);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('Nu kör vi!'), findsNothing);
    },
  );
}
