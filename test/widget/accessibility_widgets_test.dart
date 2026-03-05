import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/domain/entities/question.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';
import 'package:math_game_app/presentation/widgets/answer_button.dart';
import 'package:math_game_app/presentation/widgets/progress_indicator_bar.dart';
import 'package:math_game_app/presentation/widgets/question_card.dart';

void main() {
  Widget wrapForTest(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('[Widget] Accessibility – Quick wins', () {
    testWidgets('AnswerButton exponerar semantiklabel', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester
          .pumpWidget(wrapForTest(AnswerButton(answer: 12, onPressed: () {})));

      expect(find.bySemanticsLabel('Svar 12'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('ProgressIndicatorBar exponerar label + value', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester
          .pumpWidget(wrapForTest(const ProgressIndicatorBar(progress: 0.42)));

      expect(find.bySemanticsLabel('Framsteg'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('QuestionCard exponerar frågesemantik', (tester) async {
      final semantics = tester.ensureSemantics();
      const question = Question(
        id: 'q1',
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        operand1: 2,
        operand2: 3,
        correctAnswer: 5,
      );

      await tester.pumpWidget(
        wrapForTest(
          const SizedBox(
            height: 500,
            child: QuestionCard(question: question),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Fråga: 2 + 3. Vad blir resultatet?'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
