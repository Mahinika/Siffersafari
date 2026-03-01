import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../domain/entities/question.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import '../config/difficulty_config.dart';

/// Service for generating math questions
class QuestionGeneratorService {
  final _random = Random();
  final _uuid = const Uuid();

  int _randomInRange(NumberRange range) {
    return range.min + _random.nextInt(range.max - range.min + 1);
  }

  /// Generate a list of questions for a quiz session
  List<Question> generateQuestions({
    required AgeGroup ageGroup,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    required int count,
    Map<OperationType, int>? difficultyStepsByOperation,
    int? difficultyStep,
    int? gradeLevel,
  }) {
    final questions = <Question>[];

    for (var i = 0; i < count; i++) {
      final question = generateQuestion(
        ageGroup: ageGroup,
        operationType: operationType,
        difficulty: difficulty,
        difficultyStepsByOperation: difficultyStepsByOperation,
        difficultyStep: difficultyStep,
        gradeLevel: gradeLevel,
      );
      questions.add(question);
    }

    return questions;
  }

  /// Generate a single question
  Question generateQuestion({
    required AgeGroup ageGroup,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    Map<OperationType, int>? difficultyStepsByOperation,
    int? difficultyStep,
    int? gradeLevel,
  }) {
    final operation = operationType == OperationType.mixed
        ? _getRandomOperation()
        : operationType;

    final step = difficultyStepsByOperation != null
        ? (difficultyStepsByOperation[operation] ??
            DifficultyConfig.initialStepForDifficulty(difficulty))
        : (difficultyStep ??
            DifficultyConfig.initialStepForDifficulty(difficulty));

    final range = gradeLevel == null
        ? DifficultyConfig.getNumberRangeForStep(
            ageGroup,
            operation,
            step,
          )
        : DifficultyConfig.curriculumNumberRangeForStep(
            gradeLevel: gradeLevel,
            operationType: operation,
            difficultyStep: step,
          );

    switch (operation) {
      case OperationType.addition:
        return _generateAddition(
          range,
          difficulty,
          gradeLevel: gradeLevel,
          difficultyStep: step,
        );
      case OperationType.subtraction:
        return _generateSubtraction(
          range,
          difficulty,
          gradeLevel: gradeLevel,
          difficultyStep: step,
        );
      case OperationType.multiplication:
        return _generateMultiplication(range, difficulty);
      case OperationType.division:
        return _generateDivision(range, difficulty);
      case OperationType.mixed:
        return generateQuestion(
          ageGroup: ageGroup,
          operationType: _getRandomOperation(),
          difficulty: difficulty,
          difficultyStepsByOperation: difficultyStepsByOperation,
          difficultyStep: difficultyStep,
          gradeLevel: gradeLevel,
        );
    }
  }

  OperationType _getRandomOperation() {
    final operations = [
      OperationType.addition,
      OperationType.subtraction,
      OperationType.multiplication,
      OperationType.division,
    ];
    return operations[_random.nextInt(operations.length)];
  }

  Question _generateAddition(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int? gradeLevel,
    required int difficultyStep,
  }) {
    // Simple curriculum shaping:
    // - Åk 1: early steps focus on sums within 10 + tiokompisar.
    // - Åk 2: early steps avoid carry (no tiotalsövergång).
    final isGrade1 = gradeLevel == 1;
    final isGrade2 = gradeLevel == 2;

    final enforceSumWithin10 = isGrade1 && difficultyStep <= 4;
    final avoidCarry = isGrade2 && difficultyStep <= 4;

    int operand1;
    int operand2;

    // Bias: tiokompisar in Åk 1 when range allows.
    if (isGrade1 && range.max >= 10 && _random.nextDouble() < 0.35) {
      operand1 = _randomInRange(const NumberRange(0, 10));
      operand2 = 10 - operand1;
    } else {
      // Rejection sampling with a small cap for stability.
      operand1 = _randomInRange(range);
      operand2 = _randomInRange(range);
      for (var i = 0; i < 60; i++) {
        if (enforceSumWithin10 && operand1 + operand2 > 10) {
          operand1 = _randomInRange(range);
          operand2 = _randomInRange(range);
          continue;
        }

        if (avoidCarry && (operand1 % 10) + (operand2 % 10) >= 10) {
          operand1 = _randomInRange(range);
          operand2 = _randomInRange(range);
          continue;
        }

        break;
      }
    }
    final correctAnswer = operand1 + operand2;

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.addition,
      difficulty: difficulty,
      operand1: operand1,
      operand2: operand2,
      correctAnswer: correctAnswer,
      wrongAnswers: _generateWrongAnswers(correctAnswer, 3),
      explanation: '$operand1 + $operand2 = $correctAnswer',
    );
  }

  Question _generateSubtraction(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int? gradeLevel,
    required int difficultyStep,
  }) {
    // Ensure no negative results for younger children
    final isGrade1 = gradeLevel == 1;
    final isGrade2 = gradeLevel == 2;

    // Åk 2 early: avoid borrowing.
    final avoidBorrow = isGrade2 && difficultyStep <= 4;
    // Åk 1 early: keep within 0–10-ish and bias towards 10-x.
    final keepSmall = isGrade1 && difficultyStep <= 4;

    var operand1 = _randomInRange(range);
    var operand2 = _randomInRange(range);

    if (isGrade1 && range.max >= 10 && _random.nextDouble() < 0.35) {
      operand1 = 10;
      operand2 = _randomInRange(const NumberRange(0, 10));
    }

    for (var i = 0; i < 60; i++) {
      if (operand2 > operand1) {
        final temp = operand1;
        operand1 = operand2;
        operand2 = temp;
      }

      if (keepSmall && operand1 > 10) {
        operand1 = _randomInRange(range);
        operand2 = _randomInRange(range);
        continue;
      }

      if (avoidBorrow && (operand1 % 10) < (operand2 % 10)) {
        operand1 = _randomInRange(range);
        operand2 = _randomInRange(range);
        continue;
      }

      break;
    }

    final correctAnswer = operand1 - operand2;

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.subtraction,
      difficulty: difficulty,
      operand1: operand1,
      operand2: operand2,
      correctAnswer: correctAnswer,
      wrongAnswers: _generateWrongAnswers(correctAnswer, 3),
      explanation: '$operand1 - $operand2 = $correctAnswer',
    );
  }

  Question _generateMultiplication(
    NumberRange range,
    DifficultyLevel difficulty,
  ) {
    final operand1 = _randomInRange(range);
    final operand2 = _randomInRange(range);
    final correctAnswer = operand1 * operand2;

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.multiplication,
      difficulty: difficulty,
      operand1: operand1,
      operand2: operand2,
      correctAnswer: correctAnswer,
      wrongAnswers: _generateWrongAnswers(correctAnswer, 3),
      explanation: '$operand1 × $operand2 = $correctAnswer',
    );
  }

  Question _generateDivision(NumberRange range, DifficultyLevel difficulty) {
    // Generate division that results in whole numbers
    // Avoid division by zero and keep questions meaningful by avoiding quotient=0.
    final safeMin = max(1, range.min);
    final safeMax = max(safeMin, range.max);

    final divisor = _randomInRange(NumberRange(safeMin, safeMax));
    final quotient = _randomInRange(NumberRange(safeMin, safeMax));
    final dividend = divisor * quotient;

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.division,
      difficulty: difficulty,
      operand1: dividend,
      operand2: divisor,
      correctAnswer: quotient,
      wrongAnswers: _generateWrongAnswers(quotient, 3),
      explanation: '$dividend ÷ $divisor = $quotient',
    );
  }

  List<int> _generateWrongAnswers(int correctAnswer, int count) {
    final wrongAnswers = <int>{};
    final range = max(10, correctAnswer ~/ 2);

    while (wrongAnswers.length < count) {
      var wrongAnswer = correctAnswer + _random.nextInt(range * 2) - range;

      // Ensure wrong answer is not negative and not the correct answer
      if (wrongAnswer < 0) wrongAnswer = -wrongAnswer;
      if (wrongAnswer == correctAnswer) continue;

      wrongAnswers.add(wrongAnswer);
    }

    return wrongAnswers.toList();
  }
}
