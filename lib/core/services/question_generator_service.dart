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
    bool? missingNumberEnabled,
    double? missingNumberChance,
  })  : _random = random ?? Random(),
        _uuid = uuid ?? const Uuid(),
        _wordProblemsEnabled =
            wordProblemsEnabled ?? AppFeatures.wordProblemsEnabled,
        _wordProblemsChance =
            wordProblemsChance ?? AppFeatures.wordProblemsChance,
        _missingNumberEnabled =
            missingNumberEnabled ?? AppFeatures.missingNumberEnabled,
        _missingNumberChance =
            missingNumberChance ?? AppFeatures.missingNumberChance;

  final Random _random;
  final Uuid _uuid;

  final bool _wordProblemsEnabled;
  final double _wordProblemsChance;

  final bool _missingNumberEnabled;
  final double _missingNumberChance;

  int _randomInRange(NumberRange range) {
    return range.min + _random.nextInt(range.max - range.min + 1);
  }

  bool _hasCarry(int a, int b) {
    var x = a;
    var y = b;
    while (x > 0 || y > 0) {
      if ((x % 10) + (y % 10) >= 10) return true;
      x ~/= 10;
      y ~/= 10;
    }
    return false;
  }

  /// Returns true if `a - b` requires at least one borrow.
  /// Assumes `a >= b`.
  bool _hasBorrow(int a, int b) {
    var x = a;
    var y = b;
    var borrow = 0;

    while (x > 0 || y > 0) {
      final da = (x % 10) - borrow;
      final db = y % 10;
      if (da < db) return true;
      borrow = da < db ? 1 : 0;
      x ~/= 10;
      y ~/= 10;
    }

    return false;
  }

  List<int> _sortedCopy(List<int> values) {
    final copy = List<int>.from(values);
    copy.sort();
    return copy;
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
    bool? missingNumberEnabledOverride,
    double? missingNumberChanceOverride,
  }) {
    final wordProblemsEnabled =
        wordProblemsEnabledOverride ?? _wordProblemsEnabled;
    final wordProblemsChance =
        wordProblemsChanceOverride ?? _wordProblemsChance;

    final missingNumberEnabled =
        missingNumberEnabledOverride ?? _missingNumberEnabled;
    final missingNumberChance =
        missingNumberChanceOverride ?? _missingNumberChance;

    final operation = operationType == OperationType.mixed
        ? _getRandomOperation()
        : operationType;

    final shouldTryMissingNumber = missingNumberEnabled &&
        gradeLevel != null &&
        gradeLevel >= 2 &&
        gradeLevel <= 3 &&
        (operation == OperationType.addition ||
            operation == OperationType.subtraction) &&
        _random.nextDouble() < missingNumberChance;

    final roll = _random.nextDouble();

    final shouldTryM4Statistics = operationType == OperationType.mixed &&
      gradeLevel != null &&
      gradeLevel >= 4 &&
      gradeLevel <= 6 &&
      roll < 0.18;

    final shouldTryWordProblemAddSub = wordProblemsEnabled &&
        gradeLevel != null &&
        gradeLevel >= 1 &&
        gradeLevel <= 3 &&
        roll < wordProblemsChance &&
        (operation == OperationType.addition ||
            operation == OperationType.subtraction);

    // Conservative rollout: only Åk 3 for ×/÷ text problems.
    final shouldTryWordProblemMulDiv = wordProblemsEnabled &&
        gradeLevel == 3 &&
        roll < wordProblemsChance &&
        (operation == OperationType.multiplication ||
            operation == OperationType.division);

    final step = difficultyStepsByOperation != null
        ? (difficultyStepsByOperation[operation] ??
            DifficultyConfig.initialStepForDifficulty(difficulty))
        : (difficultyStep ??
            DifficultyConfig.initialStepForDifficulty(difficulty));

    if (shouldTryM4Statistics) {
      // Use addition's step/range as the base for value scaling.
      final statsStep = difficultyStepsByOperation != null
          ? (difficultyStepsByOperation[OperationType.addition] ??
              DifficultyConfig.initialStepForDifficulty(difficulty))
          : (difficultyStep ?? DifficultyConfig.initialStepForDifficulty(
              difficulty,
            ));

      final statsRange = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: gradeLevel,
        operationType: OperationType.addition,
        difficultyStep: statsStep,
      );

      return _generateM4StatisticsQuestion(
        statsRange,
        difficulty,
        difficultyStep: statsStep,
      );
    }

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
        if (shouldTryMissingNumber) {
          return _generateAdditionMissingNumber(
            range,
            difficulty,
            gradeLevel: gradeLevel,
            difficultyStep: step,
          );
        }
        if (shouldTryWordProblemAddSub) {
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
        if (shouldTryMissingNumber) {
          return _generateSubtractionMissingNumber(
            range,
            difficulty,
            gradeLevel: gradeLevel,
            difficultyStep: step,
          );
        }
        if (shouldTryWordProblemAddSub) {
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
        if (shouldTryWordProblemMulDiv) {
          return _generateMultiplicationWordProblem(
            range,
            difficulty,
          );
        }
        if (gradeLevel != null && gradeLevel >= 4 && gradeLevel <= 6) {
          return _generateMultiplicationCurriculum(
            range,
            difficulty,
            difficultyStep: step,
          );
        }
        return _generateMultiplication(range, difficulty);
      case OperationType.division:
        if (shouldTryWordProblemMulDiv) {
          return _generateDivisionWordProblem(
            range,
            difficulty,
          );
        }
        if (gradeLevel != null && gradeLevel >= 4 && gradeLevel <= 6) {
          return _generateDivisionCurriculum(
            range,
            difficulty,
            difficultyStep: step,
          );
        }
        return _generateDivision(range, difficulty);
      case OperationType.mixed:
        return generateQuestion(
          ageGroup: ageGroup,
          operationType: _getRandomOperation(),
          difficulty: difficulty,
          difficultyStepsByOperation: difficultyStepsByOperation,
          difficultyStep: difficultyStep,
          gradeLevel: gradeLevel,
          wordProblemsEnabledOverride: wordProblemsEnabledOverride,
          wordProblemsChanceOverride: wordProblemsChanceOverride,
          missingNumberEnabledOverride: missingNumberEnabledOverride,
          missingNumberChanceOverride: missingNumberChanceOverride,
        );
    }
  }

  Question _generateM4StatisticsQuestion(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 (Åk 4–6, quiz-format utan ny UI): enkel statistik som alltid ger
    // heltalssvar.
    // Vi inkluderar '=' i prompten för att UI ska dölja operationssymbolen.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final valueCap = step <= 3
        ? min(range.max, 200)
        : step <= 6
            ? min(range.max, 1000)
            : min(range.max, 10000);
    final valueRange = NumberRange(max(1, range.min), max(1, valueCap));

    // Deterministic progression by step (simpler early):
    // 1–3: typvärde, 4–6: median, 7–9: medelvärde (heltal), 10: variationsbredd.
    if (step <= 3) {
      final modeVal = _randomInRange(valueRange);
      var other1 = _randomInRange(valueRange);
      var other2 = _randomInRange(valueRange);
      for (var i = 0; i < 40; i++) {
        if (other1 == modeVal) other1 = _randomInRange(valueRange);
        if (other2 == modeVal || other2 == other1) {
          other2 = _randomInRange(valueRange);
        }
        if (other1 != modeVal && other2 != modeVal && other2 != other1) break;
      }

      final values = <int>[modeVal, modeVal, modeVal, other1, other2];
      values.shuffle(_random);

      final prompt = 'Typvärde = ?\nTalen: ${values.join(', ')}';
      return Question(
        id: _uuid.v4(),
        operationType: OperationType.mixed,
        difficulty: difficulty,
        operand1: 0,
        operand2: 0,
        correctAnswer: modeVal,
        wrongAnswers: _generateWrongAnswers(modeVal, 3),
        promptText: prompt,
        explanation: 'Typvärde är det tal som förekommer flest gånger.',
      );
    }

    if (step <= 6) {
      final count = step <= 5 ? 5 : 7;
      final values = List<int>.generate(count, (_) => _randomInRange(valueRange));
      final sorted = _sortedCopy(values);
      final median = sorted[sorted.length ~/ 2];

      final prompt = 'Median = ?\nTalen: ${values.join(', ')}';
      return Question(
        id: _uuid.v4(),
        operationType: OperationType.mixed,
        difficulty: difficulty,
        operand1: 0,
        operand2: 0,
        correctAnswer: median,
        wrongAnswers: _generateWrongAnswers(median, 3),
        promptText: prompt,
        explanation: 'Sortera talen. Medianen är det mittersta talet.',
      );
    }

    if (step >= 10) {
      // Variationsbredd = max - min.
      List<int> values;
      for (var attempt = 0; attempt < 120; attempt++) {
        values = List<int>.generate(6, (_) => _randomInRange(valueRange));
        final sorted = _sortedCopy(values);
        final minVal = sorted.first;
        final maxVal = sorted.last;
        if (maxVal != minVal) {
          final spread = maxVal - minVal;
          final prompt = 'Variationsbredd = ?\nTalen: ${values.join(', ')}';
          return Question(
            id: _uuid.v4(),
            operationType: OperationType.mixed,
            difficulty: difficulty,
            operand1: 0,
            operand2: 0,
            correctAnswer: spread,
            wrongAnswers: _generateWrongAnswers(spread, 3),
            promptText: prompt,
            explanation:
                'Variationsbredd = största talet - minsta talet. $maxVal - $minVal = $spread.',
          );
        }
      }
    }

    // step 7–10: medelvärde (heltal).
    // Rejection sampling: 4 tal där summan är delbar med 4.
    List<int> values;
    int mean;
    for (var attempt = 0; attempt < 120; attempt++) {
      values = List<int>.generate(4, (_) => _randomInRange(valueRange));
      final sum = values.fold<int>(0, (acc, v) => acc + v);
      if (sum % values.length == 0) {
        mean = sum ~/ values.length;
        final prompt = 'Medelvärde = ?\nTalen: ${values.join(', ')}';
        return Question(
          id: _uuid.v4(),
          operationType: OperationType.mixed,
          difficulty: difficulty,
          operand1: 0,
          operand2: 0,
          correctAnswer: mean,
          wrongAnswers: _generateWrongAnswers(mean, 3),
          promptText: prompt,
          explanation:
              'Medelvärde = summa / antal tal. Summa=$sum, antal=${values.length}.',
        );
      }
    }

    // Fallback (should be rare): use median.
    final fallback = List<int>.generate(5, (_) => _randomInRange(valueRange));
    final median = _sortedCopy(fallback)[2];
    final prompt = 'Median = ?\nTalen: ${fallback.join(', ')}';
    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: median,
      wrongAnswers: _generateWrongAnswers(median, 3),
      promptText: prompt,
      explanation: 'Sortera talen. Medianen är det mittersta talet.',
    );
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

    // M3 (Åk 4–6): bigger numbers but introduce carry gradually.
    final isM3Grade = gradeLevel != null && gradeLevel >= 4 && gradeLevel <= 6;
    final avoidCarryAllDigits = isM3Grade && difficultyStep <= 3;
    final requireCarrySomewhere = isM3Grade && difficultyStep >= 8;

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
      for (var i = 0; i < 120; i++) {
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

        if (avoidCarryAllDigits && _hasCarry(operand1, operand2)) {
          operand1 = _randomInRange(range);
          operand2 = _randomInRange(range);
          continue;
        }

        if (requireCarrySomewhere && !_hasCarry(operand1, operand2)) {
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

  Question _generateAdditionMissingNumber(
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

    final sum = base.correctAnswer;
    final missingLeft = _random.nextBool();

    final prompt = missingLeft
        ? '? + ${base.operand2} = $sum'
        : '${base.operand1} + ? = $sum';
    final correctMissing = missingLeft ? base.operand1 : base.operand2;

    return base.copyWith(
      promptText: prompt,
      correctAnswer: correctMissing,
      wrongAnswers: _generateWrongAnswers(correctMissing, 3),
      explanation: '${base.operand1} + ${base.operand2} = $sum',
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

    // M3 (Åk 4–6): bigger numbers but introduce borrowing gradually.
    final isM3Grade = gradeLevel != null && gradeLevel >= 4 && gradeLevel <= 6;
    final avoidBorrowAllDigits = isM3Grade && difficultyStep <= 3;
    final requireBorrowSomewhere = isM3Grade && difficultyStep >= 8;

    var operand1 = _randomInRange(range);
    var operand2 = _randomInRange(range);

    if (isGrade1 && range.max >= 10 && _random.nextDouble() < 0.35) {
      operand1 = 10;
      operand2 = _randomInRange(const NumberRange(0, 10));
    }

    for (var i = 0; i < 120; i++) {
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

      if (avoidBorrowAllDigits && _hasBorrow(operand1, operand2)) {
        operand1 = _randomInRange(range);
        operand2 = _randomInRange(range);
        continue;
      }

      if (requireBorrowSomewhere && !_hasBorrow(operand1, operand2)) {
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

  Question _generateSubtractionMissingNumber(
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

    final result = base.correctAnswer;
    final missingLeft = _random.nextBool();

    final prompt = missingLeft
        ? '? - ${base.operand2} = $result'
        : '${base.operand1} - ? = $result';
    final correctMissing = missingLeft ? base.operand1 : base.operand2;

    return base.copyWith(
      promptText: prompt,
      correctAnswer: correctMissing,
      wrongAnswers: _generateWrongAnswers(correctMissing, 3),
      explanation: '${base.operand1} - ${base.operand2} = $result',
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

  String _pickMultiplicationPrompt({required int a, required int b}) {
    final templates = <String Function(int, int)>[
      (x, y) => 'Du har $y påsar med $x kulor i varje. Hur många kulor är det?',
      (x, y) =>
          'Det finns $y rader med $x stolar i varje rad. Hur många stolar?',
      (x, y) =>
          'Du bygger $y torn med $x klossar i varje torn. Hur många klossar?',
      (x, y) =>
          'I en bok finns $y kapitel med $x sidor i varje. Hur många sidor?',
      (x, y) =>
          'Du har $y lådor med $x bollar i varje. Hur många bollar totalt?',
    ];

    final pick = templates[_random.nextInt(templates.length)];
    return pick(a, b);
  }

  String _pickDivisionPrompt({required int a, required int b}) {
    final templates = <String Function(int, int)>[
      (x, y) =>
          'Du har $x godisbitar och delar dem lika på $y barn. Hur många får varje?',
      (x, y) =>
          'Det finns $x kort. De delas i $y lika stora högar. Hur många i varje hög?',
      (x, y) =>
          'Du har $x äpplen och lägger $y äpplen i varje påse. Hur många påsar blir det?',
      (x, y) =>
          'En klass har $x pennor. $y pennor delas ut till varje bord. Hur många bord får pennor?',
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

  Question _generateMultiplicationCurriculum(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // Åk 4–6: börja med tabeller (<=12) mot större tal och skala sedan upp.
    // Steg 1–10: minst en faktor i tabell-området för att hålla progressionen
    // förutsägbar i quiz-formatet.
    DifficultyConfig.clampDifficultyStep(difficultyStep);

    // Avoid 0 to keep questions meaningful.
    final safeMin = max(1, range.min);
    final safeMax = max(safeMin, range.max);

    final smallMax = min(12, safeMax);

    final a = _randomInRange(NumberRange(safeMin, safeMax));
    final b = _randomInRange(NumberRange(safeMin, smallMax));

    // Randomize which one is the smaller factor for variety.
    final swap = _random.nextBool();
    final operand1 = swap ? b : a;
    final operand2 = swap ? a : b;
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

  Question _generateMultiplicationWordProblem(
    NumberRange range,
    DifficultyLevel difficulty,
  ) {
    // Avoid 0 in story problems.
    final safeMin = max(1, range.min);
    final safeMax = max(safeMin, range.max);

    final base = _generateMultiplication(
      NumberRange(safeMin, safeMax),
      difficulty,
    );

    final prompt = _pickMultiplicationPrompt(
      a: base.operand1,
      b: base.operand2,
    );

    return base.copyWith(
      promptText: prompt,
      explanation:
          '${base.operand1} × ${base.operand2} = ${base.correctAnswer}',
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

  Question _generateDivisionCurriculum(
    NumberRange range,
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // Åk 4–6 (quiz-format): håll divisionen i heltal (utan rest) men skala upp.
    // Steg 1–10: divisor hålls i tabell-området (<=12) för trygg progression.
    DifficultyConfig.clampDifficultyStep(difficultyStep);

    final safeMin = max(1, range.min);
    final safeMax = max(safeMin, range.max);

    final smallMax = min(12, safeMax);

    final divisor = _randomInRange(NumberRange(safeMin, smallMax));
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

  Question _generateDivisionWordProblem(
    NumberRange range,
    DifficultyLevel difficulty,
  ) {
    final base = _generateDivision(range, difficulty);

    final prompt = _pickDivisionPrompt(
      a: base.operand1,
      b: base.operand2,
    );

    return base.copyWith(
      promptText: prompt,
      explanation:
          '${base.operand1} ÷ ${base.operand2} = ${base.correctAnswer}',
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
