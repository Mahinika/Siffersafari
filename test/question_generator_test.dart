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

    test('generates correct number of questions', () {
      final questions = service.generateQuestions(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        count: 10,
      );

      expect(questions.length, 10);
    });

    test('generates addition question with correct result', () {
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

    test('generates subtraction question with non-negative result', () {
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

    test('generates multiplication question with correct result', () {
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

    test('generates division question with whole number result', () {
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

    test('respects number range for young age group', () {
      final questions = service.generateQuestions(
        ageGroup: AgeGroup.young,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        count: 20,
      );

      final range = DifficultyConfig.getNumberRange(
        AgeGroup.young,
        OperationType.addition,
        DifficultyLevel.easy,
      );

      for (final question in questions) {
        expect(question.operand1, greaterThanOrEqualTo(range.min));
        expect(question.operand1, lessThanOrEqualTo(range.max));
        expect(question.operand2, greaterThanOrEqualTo(range.min));
        expect(question.operand2, lessThanOrEqualTo(range.max));
      }
    });

    test('generates wrong answers that are different from correct answer', () {
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

    test('all answer options include correct answer', () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.medium,
      );

      final allOptions = question.allAnswerOptions;
      expect(allOptions.contains(question.correctAnswer), true);
    });
  });

  group('DifficultyConfig', () {
    test('returns appropriate time limit for age group', () {
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

    test('returns more questions for older age groups', () {
      final youngQuestions = DifficultyConfig.getQuestionsPerSession(
        AgeGroup.young,
      );
      final olderQuestions = DifficultyConfig.getQuestionsPerSession(
        AgeGroup.older,
      );

      expect(olderQuestions, greaterThanOrEqualTo(youngQuestions));
    });

    test('number range max is greater than min', () {
      final range = DifficultyConfig.getNumberRange(
        AgeGroup.middle,
        OperationType.addition,
        DifficultyLevel.medium,
      );

      expect(range.max, greaterThan(range.min));
    });
  });
}
