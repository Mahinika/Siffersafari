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

  /// Generate a list of questions for a quiz session
  List<Question> generateQuestions({
    required AgeGroup ageGroup,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    required int count,
  }) {
    final questions = <Question>[];

    for (var i = 0; i < count; i++) {
      final question = generateQuestion(
        ageGroup: ageGroup,
        operationType: operationType,
        difficulty: difficulty,
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
  }) {
    final range = DifficultyConfig.getNumberRange(
      ageGroup,
      operationType,
      difficulty,
    );

    final operation = operationType == OperationType.mixed
        ? _getRandomOperation()
        : operationType;

    switch (operation) {
      case OperationType.addition:
        return _generateAddition(range, difficulty);
      case OperationType.subtraction:
        return _generateSubtraction(range, difficulty);
      case OperationType.multiplication:
        return _generateMultiplication(range, difficulty);
      case OperationType.division:
        return _generateDivision(range, difficulty);
      case OperationType.mixed:
        return generateQuestion(
          ageGroup: ageGroup,
          operationType: _getRandomOperation(),
          difficulty: difficulty,
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

  Question _generateAddition(NumberRange range, DifficultyLevel difficulty) {
    final operand1 = _randomInRange(range);
    final operand2 = _randomInRange(range);
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
    DifficultyLevel difficulty,
  ) {
    // Ensure no negative results for younger children
    var operand1 = _randomInRange(range);
    var operand2 = _randomInRange(range);

    if (operand2 > operand1) {
      final temp = operand1;
      operand1 = operand2;
      operand2 = temp;
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
    final divisor = _randomInRange(
      NumberRange(max(1, range.min), range.max),
    ); // Avoid division by zero
    final quotient = _randomInRange(range);
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

  int _randomInRange(NumberRange range) {
    return range.min + _random.nextInt(range.max - range.min + 1);
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
