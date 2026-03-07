import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/constants/app_constants.dart';
import 'package:siffersafari/domain/entities/user_progress.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/main.dart';

import '../test_utils.dart';

void main() {
  late InMemoryLocalStorageRepository repository;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    repository = await setupWidgetTestDependencies();
  });

  testWidgets(
    '[Widget] Quiz – complete full session and replay',
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
      expect(find.text('Djungelspår'), findsOneWidget);
      expect(find.textContaining('Ville:'), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await pumpUntilFound(tester, find.text('Nästa!'));

        expect(find.text('Nästa!'), findsOneWidget);
        await tester.ensureVisible(find.text('Nästa!'));
        await tester.tap(find.text('Nästa!'));

        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.textContaining('Spela igen'));

      expect(find.textContaining('Spela igen'), findsOneWidget);

      await tester.ensureVisible(find.textContaining('Spela igen'));
      await tester.tap(find.textContaining('Spela igen'));
      await pumpUntilFound(tester, find.textContaining('Fråga'));

      expect(find.textContaining('Fråga'), findsOneWidget);
    },
  );
}
