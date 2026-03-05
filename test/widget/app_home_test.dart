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
    '[Widget] App home – displays title',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(
        tester,
        find.text('Skapa profil'),
        timeout: const Duration(seconds: 8),
      );

      final titleFinder = find.text(AppConstants.appName);
      if (titleFinder.evaluate().isEmpty) {
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? t.textSpan?.toPlainText())
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        fail(
          'Kunde inte hitta app-titeln "${AppConstants.appName}". '
          'Tillgängliga texter: ${texts.take(80).toList()}',
        );
      }

      expect(titleFinder, findsOneWidget);
    },
  );

  testWidgets(
    '[Widget] App home – profile selector with multiple profiles',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const user1 = UserProgress(
        userId: 'u1',
        name: 'Alex',
        ageGroup: AgeGroup.middle,
        avatarEmoji: '🐯',
      );
      const user2 = UserProgress(
        userId: 'u2',
        name: 'Sam',
        ageGroup: AgeGroup.middle,
        avatarEmoji: '🦊',
      );
      await repository.saveUserProgress(user1);
      await repository.saveUserProgress(user2);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text('Välj spelare'));

      expect(find.text('Välj spelare'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    },
  );
}
