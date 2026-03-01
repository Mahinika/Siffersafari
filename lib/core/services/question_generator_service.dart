import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../domain/entities/question.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import '../config/app_features.dart';
import '../config/difficulty_config.dart';

/// Service for generating math questions
class QuestionGeneratorService {
  QuestionGeneratorService({
    Random? random,
    Uuid? uuid,
    bool? wordProblemsEnabled,
    double? wordProblemsChance,
  })  : _random = random ?? Random(),
        _uuid = uuid ?? const Uuid(),
        _wordProblemsEnabled =
            wordProblemsEnabled ?? AppFeatures.wordProblemsEnabled,
        _wordProblemsChance =
            wordProblemsChance ?? AppFeatures.wordProblemsChance;

  final Random _random;
  final Uuid _uuid;

  final bool _wordProblemsEnabled;
  final double _wordProblemsChance;

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
    bool? wordProblemsEnabledOverride,
    double? wordProblemsChanceOverride,
  }) {
    final wordProblemsEnabled =
        wordProblemsEnabledOverride ?? _wordProblemsEnabled;
    final wordProblemsChance =
        wordProblemsChanceOverride ?? _wordProblemsChance;

    final operation = operationType == OperationType.mixed
        ? _getRandomOperation()
        : operationType;

    final shouldTryWordProblem = wordProblemsEnabled &&
        gradeLevel != null &&
        gradeLevel >= 1 &&
        gradeLevel <= 3 &&
        _random.nextDouble() < wordProblemsChance &&
        (operation == OperationType.addition ||
            operation == OperationType.subtraction);

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
        if (shouldTryWordProblem) {
          return _generateAdditionWordProblem(
            range,
            difficulty,
            gradeLevel: gradeLevel,
            difficultyStep: step,
          );
        }
        return _generateAddition(
          range,
          difficulty,
          gradeLevel: gradeLevel,
          difficultyStep: step,
        );
      case OperationType.subtraction:
        if (shouldTryWordProblem) {
          return _generateSubtractionWordProblem(
            range,
            difficulty,
            gradeLevel: gradeLevel,
            difficultyStep: step,
          );
        }
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

  Question _generateAdditionWordProblem(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int? gradeLevel,
    required int difficultyStep,
  }) {
    final base = _generateAddition(
      range,
      difficulty,
      gradeLevel: gradeLevel,
      difficultyStep: difficultyStep,
    );

    final prompt = _pickAdditionPrompt(
      a: base.operand1,
      b: base.operand2,
    );

    return base.copyWith(
      promptText: prompt,
      explanation:
          '${base.operand1} + ${base.operand2} = ${base.correctAnswer}',
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

  Question _generateSubtractionWordProblem(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int? gradeLevel,
    required int difficultyStep,
  }) {
    final base = _generateSubtraction(
      range,
      difficulty,
      gradeLevel: gradeLevel,
      difficultyStep: difficultyStep,
    );

    final prompt = _pickSubtractionPrompt(
      a: base.operand1,
      b: base.operand2,
    );

    return base.copyWith(
      promptText: prompt,
      explanation:
          '${base.operand1} - ${base.operand2} = ${base.correctAnswer}',
    );
  }

  // --- Word problem templates (Åk 1–3, 1-step) ---
  // We keep Swedish prompts short and avoid tricky pluralization.

  String _pickAdditionPrompt({required int a, required int b}) {
    final templates = <String Function(int, int)>[
      (x, y) => 'Du har $x kulor och får $y fler. Hur många kulor har du nu?',
      (x, y) =>
          'På bordet ligger $x pennor. Du lägger dit $y till. Hur många pennor blir det?',
      (x, y) =>
          'Lisa har $x klossar och får $y till. Hur många klossar har hon nu?',
      (x, y) =>
          'I en burk finns $x knappar. Du lägger i $y till. Hur många knappar finns nu?',
      (x, y) => 'Du har $x kort. Du får $y kort till. Hur många kort har du?',
      (x, y) =>
          'I en låda ligger $x bollar. Du lägger i $y bollar till. Hur många bollar finns?',
      (x, y) =>
          'Det är $x barn i parken. $y barn kommer. Hur många barn är där nu?',
      (x, y) =>
          'Du plockar $x stenar och plockar $y till. Hur många stenar har du?',
    ];

    final pick = templates[_random.nextInt(templates.length)];
    return pick(a, b);
  }

  String _pickSubtractionPrompt({required int a, required int b}) {
    final templates = <String Function(int, int)>[
      (x, y) => 'Du har $x ballonger. $y flyger iväg. Hur många är kvar?',
      (x, y) => 'Det finns $x fiskar. $y simmar bort. Hur många är kvar?',
      (x, y) =>
          'Du har $x godisbitar. Du äter $y. Hur många godisbitar är kvar?',
      (x, y) =>
          'I en skål finns $x frukter. Du tar $y. Hur många frukter är kvar?',
      (x, y) =>
          'På en hylla står $x böcker. Du tar bort $y. Hur många böcker står kvar?',
      (x, y) => 'Du har $x mynt. Du ger bort $y. Hur många mynt har du kvar?',
      (x, y) =>
          'Det ligger $x leksaker på golvet. Du plockar upp $y. Hur många ligger kvar?',
      (x, y) =>
          'I en låda finns $x klossar. Du tar ut $y. Hur många klossar är kvar?',
    ];

    final pick = templates[_random.nextInt(templates.length)];
    return pick(a, b);
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
