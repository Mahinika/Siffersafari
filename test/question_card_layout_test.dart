import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/domain/entities/question.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';
import 'package:math_game_app/presentation/widgets/question_card.dart';

Widget _wrapForTest(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    },
  );
}

void main() {
  testWidgets(
    'QuestionCard: RenderFlex overflowar inte i compact-läge (stora tal)',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const question = Question(
        id: 'q_big_numbers',
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.hard,
        operand1: 999,
        operand2: 999,
        correctAnswer: 998001,
        wrongAnswers: [998000, 998002, 998101],
        explanation: '999 × 999 = 998001',
      );

      await tester.pumpWidget(
        _wrapForTest(
          const SizedBox(
            height: 180,
            child: QuestionCard(question: question),
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'QuestionCard: RenderFlex overflowar inte i compact-läge (lång textuppgift)',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const question = Question(
        id: 'q_word_problem',
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.medium,
        operand1: 12,
        operand2: 12,
        correctAnswer: 144,
        promptText:
            'Alex har 12 påsar. I varje påse finns 12 kulor. Hur många kulor har Alex totalt?',
        wrongAnswers: [143, 145, 124],
      );

      await tester.pumpWidget(
        _wrapForTest(
          const SizedBox(
            height: 180,
            child: QuestionCard(question: question),
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'QuestionCard: döljer symbol när prompt är ekvation ("=")',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const question = Question(
        id: 'q_equation_prompt',
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        operand1: 0,
        operand2: 0,
        correctAnswer: 7,
        promptText: '? + 3 = 7',
        wrongAnswers: [6, 8, 9],
      );

      await tester.pumpWidget(
        _wrapForTest(
          const SizedBox(
            height: 180,
            child: QuestionCard(question: question),
          ),
        ),
      );

      await tester.pump();

      // När prompten innehåller '=', ska operation-symbolen inte visas separat.
      expect(find.text(OperationType.addition.symbol), findsNothing);
      expect(find.text('? + 3 = 7'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
