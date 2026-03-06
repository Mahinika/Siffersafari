import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/constants/app_constants.dart';
import 'package:siffersafari/core/di/injection.dart';
import 'package:siffersafari/domain/entities/user_progress.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/domain/services/parent_pin_service.dart';
import 'package:siffersafari/main.dart';

import '../test_utils.dart';

void main() {
  late InMemoryLocalStorageRepository repository;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    repository = await setupWidgetTestDependencies();
  });

  testWidgets(
    '[Widget] Parent mode – create PIN and open dashboard',
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
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text(AppConstants.appName));

      await pumpUntilFound(tester, find.byTooltip('Föräldraläge'));

      await tester.tap(find.byTooltip('Föräldraläge'));
      await pumpUntilFound(tester, find.text('Skapa PIN'));

      expect(find.text('Skapa PIN'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).at(0), '1234');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Spara PIN'));

      // Recovery setup dialog should appear after saving PIN.
      await pumpUntilFound(tester, find.text('Sätt säkerhetsfråga'));
      await tester.ensureVisible(find.text('Hoppa över'));
      await tester.tap(find.text('Hoppa över'), warnIfMissed: false);

      await pumpUntilFound(tester, find.text('Översikt'));
      expect(find.text('Översikt'), findsOneWidget);
    },
  );

  testWidgets(
    '[Widget] Parent mode – create PIN and set security question',
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
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text(AppConstants.appName));
      await pumpUntilFound(tester, find.byTooltip('Föräldraläge'));

      await tester.tap(find.byTooltip('Föräldraläge'));
      await pumpUntilFound(tester, find.text('Skapa PIN'));

      await tester.enterText(find.byType(TextField).at(0), '1234');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Spara PIN'));

      await pumpUntilFound(tester, find.text('Sätt säkerhetsfråga'));

      // Enter security answer and save.
      final answerField = find.byType(TextField).last;
      await tester.enterText(answerField, 'hemligt');
      await tester.ensureVisible(find.text('Spara säkerhetsfråga'));
      await tester.tap(find.text('Spara säkerhetsfråga'), warnIfMissed: false);

      await pumpUntilFound(tester, find.text('Översikt'));
      expect(find.text('Översikt'), findsOneWidget);

      // Ensure recovery config actually got stored.
      final pinService = getIt<ParentPinService>();
      expect(pinService.hasRecoveryConfigured(), isTrue);
      expect(pinService.getSecurityQuestion(), isNotNull);
    },
  );

  testWidgets(
    '[Widget] Parent mode – save security question with keyboard open',
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
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text(AppConstants.appName));
      await pumpUntilFound(tester, find.byTooltip('Föräldraläge'));

      await tester.tap(find.byTooltip('Föräldraläge'));
      await pumpUntilFound(tester, find.text('Skapa PIN'));

      await tester.enterText(find.byType(TextField).at(0), '1234');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Spara PIN'));

      await pumpUntilFound(tester, find.text('Sätt säkerhetsfråga'));

      // Simulate the keyboard being open while saving.
      tester.view.viewInsets = const FakeViewPadding(
        left: 0,
        top: 0,
        right: 0,
        bottom: 300,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      final answerField = find.byType(TextField).last;
      await tester.enterText(answerField, 'hemligt');
      await tester.ensureVisible(find.text('Spara säkerhetsfråga'));
      await tester.tap(find.text('Spara säkerhetsfråga'), warnIfMissed: false);

      // Catch delayed framework exceptions (e.g. overlay/global key asserts).
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);

      // And then the keyboard closes as focus is removed.
      tester.view.resetViewInsets();
      await pumpFor(tester, const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      await pumpUntilFound(tester, find.text('Översikt'));
      expect(find.text('Översikt'), findsOneWidget);

      // Give the navigation stack time to settle.
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[Widget] Parent mode – enter existing PIN and open dashboard',
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
      await repository.saveSetting('onboarding_done_$userId', true);
      final pinService = getIt<ParentPinService>();
      await pinService.setPin('1234');

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text(AppConstants.appName));

      await pumpUntilFound(tester, find.byTooltip('Föräldraläge'));

      await tester.tap(find.byTooltip('Föräldraläge'));
      await pumpUntilFound(tester, find.text('Ange PIN'));

      expect(find.text('Ange PIN'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Öppna'));

      await pumpUntilFound(tester, find.text('Översikt'));
      expect(find.text('Föräldraläge'), findsOneWidget);
      expect(find.text('Översikt'), findsOneWidget);
    },
  );
}
