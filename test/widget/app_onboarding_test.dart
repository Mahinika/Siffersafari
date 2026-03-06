import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/constants/app_constants.dart';
import 'package:siffersafari/core/providers/user_provider.dart';
import 'package:siffersafari/domain/entities/user_progress.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/presentation/screens/home_screen.dart';

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
      await repository.setActiveUserId(userId);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(userProvider.notifier).loadUsers();
      expect(container.read(userProvider).activeUser?.userId, userId);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Let HomeScreen's post-frame onboarding push run.
      await tester.pump();

      final onboardingTitle = find.text('Nu kör vi!');
      final steps = (const Duration(seconds: 2).inMilliseconds / 50).ceil();
      for (var i = 0; i < steps; i++) {
        if (onboardingTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(onboardingTitle, findsOneWidget);

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
      await repository.setActiveUserId(userId);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(userProvider.notifier).loadUsers();
      expect(container.read(userProvider).activeUser?.userId, userId);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Let HomeScreen's post-frame onboarding push run.
      await tester.pump();

      final onboardingTitle = find.text('Nu kör vi!');
      final steps = (const Duration(seconds: 2).inMilliseconds / 50).ceil();
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

      // Regression check: addition should be preselected by default.
      final additionTile = find.widgetWithText(
        CheckboxListTile,
        'Plusraketer',
      );
      expect(additionTile, findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(additionTile).value,
        isTrue,
      );

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
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('Nu kör vi!'), findsNothing);
    },
  );
}
