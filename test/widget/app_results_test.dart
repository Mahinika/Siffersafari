import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/constants/app_constants.dart';
import 'package:siffersafari/core/constants/settings_keys.dart';
import 'package:siffersafari/domain/entities/user_progress.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/main.dart';

import '../test_utils.dart';

void main() {
  late InMemoryLocalStorageRepository repository;

  Future<void> tapContinueButton(WidgetTester tester) async {
    const timeout = Duration(seconds: 4);
    final steps = (timeout.inMilliseconds / 50).ceil().clamp(1, 400);

    for (var i = 0; i < steps; i++) {
      await skipOnboardingIfPresent(tester);

      final next = find.text('Nästa').hitTestable();
      if (next.evaluate().isNotEmpty) {
        await tester.tap(next.last, warnIfMissed: false);
        await tester.pump();
        return;
      }

      final results = find.text('Se resultat').hitTestable();
      if (results.evaluate().isNotEmpty) {
        await tester.tap(results.last, warnIfMissed: false);
        await tester.pump();
        return;
      }

      await tester.pump(const Duration(milliseconds: 50));
    }

    throw TestFailure('Kunde inte hitta fortsatt-knappen i feedbackflödet.');
  }

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    repository = await setupWidgetTestDependencies();
  });

  testWidgets(
    '[Widget] Results – quick practice session from results screen',
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
      await repository.saveSetting(SettingsKeys.onboardingDone(userId), true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final multiplication =
          find.byKey(const Key('operation_card_multiplication'));
      await pumpUntilFound(tester, multiplication);
      expect(multiplication, findsOneWidget);

      await tester.ensureVisible(multiplication);
      await tester.pump();
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 150),
      );
      await tester.tap(multiplication);
      await pumpUntilFound(tester, find.textContaining('Fråga'));
      expect(find.textContaining('Fråga'), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await tapContinueButton(tester);
        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.textContaining('Spela igen'));

      await tester.ensureVisible(find.text('Snabbträna (2 min)'));
      await tester.tap(find.text('Snabbträna (2 min)'));
      await pumpUntilFound(tester, find.textContaining('Fråga'));

      expect(find.textContaining('Fråga'), findsOneWidget);
    },
  );

  testWidgets(
    '[Widget] Results – empty focus mode when no weaknesses found',
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
      await repository.saveSetting(SettingsKeys.onboardingDone(userId), true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final multiplication =
          find.byKey(const Key('operation_card_multiplication'));
      await pumpUntilFound(tester, multiplication);
      expect(multiplication, findsOneWidget);

      await tester.ensureVisible(multiplication);
      await tester.pump();
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 150),
      );
      await tester.tap(multiplication);
      await pumpUntilFound(tester, find.textContaining('Fråga'));
      expect(find.textContaining('Fråga'), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await tapContinueButton(tester);
        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.textContaining('Spela igen'));

      await tester.ensureVisible(find.text('Snabbträna (2 min)'));
      await tester.tap(find.text('Snabbträna (2 min)'));
      await pumpUntilFound(tester, find.textContaining('Fråga'));
      expect(find.textContaining('Fråga'), findsOneWidget);
    },
  );

  testWidgets(
    '[Widget] Results – shows story checkpoint reveal after completed quest',
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
      await repository.saveSetting(SettingsKeys.onboardingDone(userId), true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final addition = find.byKey(const Key('operation_card_addition'));
      await pumpUntilFound(tester, addition);
      expect(addition, findsOneWidget);

      await tester.ensureVisible(addition);
      await tester.pump();
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 150),
      );
      await tester.tap(addition);
      await pumpUntilFound(tester, find.textContaining('Fråga'));

      for (var i = 0; i < 10; i++) {
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await tapContinueButton(tester);
        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.text('Ny checkpoint i djungeln!'));

      expect(find.text('Ny checkpoint i djungeln!'), findsOneWidget);
      expect(
        find.textContaining('Nästa mål: Hitta borttappade siffror'),
        findsWidgets,
      );
    },
  );
}
