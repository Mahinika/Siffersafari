import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('QuestionGeneratorService', () {
    late QuestionGeneratorService service;

    setUp(() {
      service = QuestionGeneratorService();
    });

    test('Unit (QuestionGeneratorService): genererar rätt antal frågor', () {
      final questions = service.generateQuestions(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        count: 10,
      );

      expect(questions.length, 10);
    });

    test('Unit (QuestionGeneratorService): addition ger korrekt svar', () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.addition);
      expect(
        question.correctAnswer,
        question.operand1 + question.operand2,
      );
    });

    test(
        'Unit (QuestionGeneratorService): subtraktion ger inte negativt resultat',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.young,
        operationType: OperationType.subtraction,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.subtraction);
      expect(question.correctAnswer, greaterThanOrEqualTo(0));
      expect(
        question.correctAnswer,
        question.operand1 - question.operand2,
      );
    });

    test('Unit (QuestionGeneratorService): multiplikation ger korrekt svar',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.multiplication);
      expect(
        question.correctAnswer,
        question.operand1 * question.operand2,
      );
    });

    test('Unit (QuestionGeneratorService): division ger heltalsresultat', () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.division,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.division);
      // Verify it's a whole number division
      expect(
        question.operand1 % question.operand2,
        0,
      );
      expect(
        question.correctAnswer,
        question.operand1 ~/ question.operand2,
      );
    });

    test('Unit (QuestionGeneratorService): respekterar talintervall för young',
        () {
      final questions = service.generateQuestions(
        ageGroup: AgeGroup.young,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        count: 20,
      );

      // Generatorn använder interna difficulty-steps och interpolerar mellan
      // easy/medium/hard. Verifiera därför mot step-baserad range.
      final step =
          DifficultyConfig.initialStepForDifficulty(DifficultyLevel.easy);
      final range = DifficultyConfig.getNumberRangeForStep(
        AgeGroup.young,
        OperationType.addition,
        step,
      );

      for (final question in questions) {
        expect(question.operand1, greaterThanOrEqualTo(range.min));
        expect(question.operand1, lessThanOrEqualTo(range.max));
        expect(question.operand2, greaterThanOrEqualTo(range.min));
        expect(question.operand2, lessThanOrEqualTo(range.max));
      }
    });

    test(
        'Unit (QuestionGeneratorService): felalternativ skiljer sig från rätt svar',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.medium,
      );

      expect(question.wrongAnswers.length, greaterThan(0));
      for (final wrongAnswer in question.wrongAnswers) {
        expect(wrongAnswer, isNot(question.correctAnswer));
      }
    });

    test(
        'Unit (QuestionGeneratorService): svarsalternativ innehåller rätt svar',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.medium,
      );

      final allOptions = question.allAnswerOptions;
      expect(allOptions.contains(question.correctAnswer), true);
    });

    test(
        'Unit (QuestionGeneratorService): kan generera textuppgift för Åk 1–3 (+/−) när påslaget',
        () {
      final wordProblemService = QuestionGeneratorService(
        wordProblemsEnabled: true,
        wordProblemsChance: 1.0,
      );

      final question = wordProblemService.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 2,
      );

      expect(question.promptText, isNotNull);
      expect(question.questionText, contains('?'));
    });
  });

  group('DifficultyConfig', () {
    test('Unit (DifficultyConfig): ger längre tidsgräns för yngre', () {
      final youngTime = DifficultyConfig.getTimeLimit(
        AgeGroup.young,
        DifficultyLevel.easy,
      );
      final olderTime = DifficultyConfig.getTimeLimit(
        AgeGroup.older,
        DifficultyLevel.easy,
      );

      // Younger children should get more time
      expect(youngTime, greaterThan(olderTime));
    });

    test('Unit (DifficultyConfig): ger fler frågor för äldre', () {
      final youngQuestions = DifficultyConfig.getQuestionsPerSession(
        AgeGroup.young,
      );
      final olderQuestions = DifficultyConfig.getQuestionsPerSession(
        AgeGroup.older,
      );

      expect(olderQuestions, greaterThanOrEqualTo(youngQuestions));
    });

    test('Unit (DifficultyConfig): talintervall har max > min', () {
      final range = DifficultyConfig.getNumberRange(
        AgeGroup.middle,
        OperationType.addition,
        DifficultyLevel.medium,
      );

      expect(range.max, greaterThan(range.min));
    });
  });
}
