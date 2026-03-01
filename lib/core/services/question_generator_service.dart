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

  int _randomSignedValue(int maxAbs) {
    final safeMaxAbs = max(1, maxAbs);
    final value = _random.nextInt(safeMaxAbs + 1);
    return _random.nextBool() ? value : -value;
  }

  int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final t = y;
      y = x % y;
      x = t;
    }
    return x == 0 ? 1 : x;
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

  List<int> _generateWrongPercentAnswers(int correctPercent, int count) {
    final wrong = <int>{};
    final correct = correctPercent.clamp(0, 100);

    // Keep wrong answers plausible and within 0..100.
    final deltas = <int>[
      -50,
      -40,
      -30,
      -25,
      -20,
      -15,
      -10,
      -5,
      5,
      10,
      15,
      20,
      25,
      30,
      40,
      50,
    ];

    for (var i = 0; i < 200 && wrong.length < count; i++) {
      final delta = deltas[_random.nextInt(deltas.length)];
      final candidate = (correct + delta).clamp(0, 100);
      if (candidate == correct) continue;
      wrong.add(candidate);
    }

    // Fallback if we somehow didn't fill.
    var cursor = 0;
    while (wrong.length < count) {
      final candidate = (cursor * 10).clamp(0, 100);
      cursor++;
      if (candidate == correct) continue;
      wrong.add(candidate);
    }

    return wrong.take(count).toList();
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

    // Use a stable baseline step for “special” Mix question types (M4).
    // We base this on addition's step to avoid the selected random operation
    // skewing how often these appear.
    final mixBaselineStep = difficultyStepsByOperation != null
        ? (difficultyStepsByOperation[OperationType.addition] ??
            DifficultyConfig.initialStepForDifficulty(difficulty))
        : (difficultyStep ??
            DifficultyConfig.initialStepForDifficulty(difficulty));

    final shouldTryMissingNumber = missingNumberEnabled &&
        gradeLevel != null &&
        gradeLevel >= 2 &&
        gradeLevel <= 3 &&
        (operation == OperationType.addition ||
            operation == OperationType.subtraction) &&
        _random.nextDouble() < missingNumberChance;

    final roll = _random.nextDouble();

    // Mix distribution for M4 (Åk 4–6): keep “special” items present but not
    // dominating, and scale them slightly with internal step.
    final isM4Mix = operationType == OperationType.mixed &&
        gradeLevel != null &&
        gradeLevel >= 4 &&
        gradeLevel <= 6;
    final isM5aMix = operationType == OperationType.mixed &&
        gradeLevel != null &&
        gradeLevel >= 7 &&
        gradeLevel <= 9;

    final clampedMixStep =
        DifficultyConfig.clampDifficultyStep(mixBaselineStep);
    final statsChance = clampedMixStep <= 3
        ? 0.10
        : clampedMixStep <= 6
            ? 0.12
            : 0.12;
    final probabilityChance = clampedMixStep <= 3
        ? 0.10
        : clampedMixStep <= 6
            ? 0.12
            : 0.12;

    final shouldTryM4Statistics = isM4Mix && roll < statsChance;
    final shouldTryM4Probability = isM4Mix &&
        roll >= statsChance &&
        roll < (statsChance + probabilityChance);
    final shouldTryM5aPercent = isM5aMix && roll < 0.18;
    final shouldTryM5aPower =
        isM5aMix && gradeLevel >= 8 && roll >= 0.18 && roll < 0.30;
    final shouldTryM5aPrecedence = isM5aMix && roll >= 0.30 && roll < 0.42;

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
      final statsStep = mixBaselineStep;

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

    if (shouldTryM4Probability) {
      final probStep = mixBaselineStep;

      return _generateM4ProbabilityQuestion(
        difficulty,
        difficultyStep: probStep,
      );
    }

    if (shouldTryM5aPercent) {
      final percentStep = mixBaselineStep;

      return _generateM5aPercentQuestion(
        difficulty,
        difficultyStep: percentStep,
      );
    }

    if (shouldTryM5aPower) {
      final powerStep = mixBaselineStep;

      return _generateM5aPowerQuestion(
        difficulty,
        difficultyStep: powerStep,
      );
    }

    if (shouldTryM5aPrecedence) {
      final precedenceStep = mixBaselineStep;

      return _generateM5aPrecedenceQuestion(
        difficulty,
        difficultyStep: precedenceStep,
      );
    }

    // M5b: Introduktion av visualiserad matematik för Åk 7–9 (steg 8+).
    // Börjar med linjära funktioner enbart i textformat.
    final shouldTryM5bLinearFunction =
        isM5aMix && clampedMixStep >= 8 && roll >= 0.42 && roll < 0.52;

    if (shouldTryM5bLinearFunction) {
      final linearStep = mixBaselineStep;

      return _generateM5bLinearFunctionQuestion(
        difficulty,
        difficultyStep: linearStep,
      );
    }

    // M5b delstep 2: Geometriska transformationer (spegling, rotation, translation)
    final shouldTryM5bGeometricTransformation =
        isM5aMix && clampedMixStep >= 8 && roll >= 0.52 && roll < 0.62;

    if (shouldTryM5bGeometricTransformation) {
      final transformStep = mixBaselineStep;

      return _generateM5bGeometricTransformationQuestion(
        difficulty,
        difficultyStep: transformStep,
      );
    }

    // M5b delstep 3: Avancerad statistik (distributioner, outliers, korrelationer)
    final shouldTryM5bAdvancedStatistics =
        isM5aMix && clampedMixStep >= 8 && roll >= 0.62 && roll < 0.72;

    if (shouldTryM5bAdvancedStatistics) {
      final statsStep = mixBaselineStep;

      return _generateM5bAdvancedStatisticsQuestion(
        difficulty,
        difficultyStep: statsStep,
      );
    }

    // M4a: Tid (klockan) för Åk 1–3 i Mix-läge
    final isM4TimeEligible = operationType == OperationType.mixed &&
        gradeLevel != null &&
        gradeLevel >= 1 &&
        gradeLevel <= 3;

    final shouldTryM4Time = isM4TimeEligible && roll >= 0.75 && roll < 0.85;

    if (shouldTryM4Time) {
      final timeStep = mixBaselineStep;

      return _generateM4TimeQuestion(
        difficulty,
        gradeLevel: gradeLevel,
        difficultyStep: timeStep,
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

    // M4 full (del 1): enkel visualiserad statistik i tabellformat.
    // Vi introducerar detta från step 6 och uppåt.
    if (step >= 6 && _random.nextDouble() < 0.22) {
      return _generateM4StatisticsTableQuestion(
        valueRange,
        difficulty,
        difficultyStep: step,
      );
    }

    // M4 full (del 2a): ASCII-stapeldiagram med tolkning-frågor.
    // Från step 7 och uppåt med låg sannolikhet.
    if (step >= 7 && _random.nextDouble() < 0.15) {
      return _generateM4BarChartQuestion(
        valueRange,
        difficulty,
        difficultyStep: step,
      );
    }

    // M4 full (del 2b): sannolikhetsvisualising med färgade bollar.
    // Från step 8 och uppåt med låg sannolikhet.
    if (step >= 8 && _random.nextDouble() < 0.12) {
      return _generateM4ProbabilityDiagramQuestion(
        difficulty,
        difficultyStep: step,
      );
    }

    // M4 full (del 3): geometri/mätning — enhetskonverteringar och formfrågor.
    // Från step 6 och uppåt med låg sannolikhet.
    if (step >= 6 && _random.nextDouble() < 0.10) {
      final roll = _random.nextDouble();
      if (roll < 0.60) {
        return _generateM4MeasurementUnitQuestion(
          difficulty,
          difficultyStep: step,
        );
      } else if (roll < 0.85) {
        return _generateM4ShapeAreaQuestion(difficulty, difficultyStep: step);
      } else {
        return _generateM4ShapePerimeterQuestion(
          difficulty,
          difficultyStep: step,
        );
      }
    }

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
      final values =
          List<int>.generate(count, (_) => _randomInRange(valueRange));
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

  Question _generateM4StatisticsTableQuestion(
    NumberRange valueRange,
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final labels = <String>['A', 'B', 'C'];
    final minVal = max(2, valueRange.min);
    final maxVal = max(minVal + 2, valueRange.max);

    int a = _randomInRange(NumberRange(minVal, maxVal));
    int b = _randomInRange(NumberRange(minVal, maxVal));
    int c = _randomInRange(NumberRange(minVal, maxVal));

    // Avoid degenerate all-equal values to keep interpretation meaningful.
    for (var i = 0; i < 60; i++) {
      if (!(a == b && b == c)) break;
      b = _randomInRange(NumberRange(minVal, maxVal));
      c = _randomInRange(NumberRange(minVal, maxVal));
    }

    final values = <int>[a, b, c];
    final sorted = _sortedCopy(values);

    final int correct;
    final String questionLine;
    final String explanation;

    if (step <= 7) {
      final maxValEntry = values.reduce((x, y) => x > y ? x : y);
      correct = maxValEntry;
      questionLine = 'Vilket värde är störst?';
      explanation =
          'Jämför alla värden i tabellen och välj det största: $correct.';
    } else if (step <= 9) {
      final diff = sorted.last - sorted.first;
      correct = diff;
      questionLine = 'Vad är skillnaden mellan största och minsta värdet?';
      explanation =
          'Skillnad = största - minsta = ${sorted.last} - ${sorted.first} = $correct.';
    } else {
      final sum = values.fold<int>(0, (acc, v) => acc + v);
      // Keep integer mean in step 10 table mode.
      if (sum % values.length == 0) {
        correct = sum ~/ values.length;
      } else {
        // Snap to a nearby divisible setup by adjusting C.
        final remainder = sum % values.length;
        c += (values.length - remainder);
        values[2] = c;
        final adjustedSum = values.fold<int>(0, (acc, v) => acc + v);
        correct = adjustedSum ~/ values.length;
      }
      questionLine = 'Vad är medelvärdet?';
      explanation =
          'Medelvärde = summa / antal = ${values.fold<int>(0, (acc, v) => acc + v)} / ${values.length} = $correct.';
    }

    final prompt =
        'Tabell (statistik) = ?\nKategori | Värde\n${labels[0]} | ${values[0]}\n${labels[1]} | ${values[1]}\n${labels[2]} | ${values[2]}\nFråga: $questionLine';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation: explanation,
    );
  }

  Question _generateM4BarChartQuestion(
    NumberRange valueRange,
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 full (del 2a): ASCII-stapeldiagram med tolkning-frågor.
    // Visa ett enkelt diagram med asterisker och ställ frågor om högsta/lägsta.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final labels = <String>['X', 'Y', 'Z'];
    final minVal = max(2, valueRange.min);
    final maxVal = max(minVal + 2, valueRange.max);

    int a = _randomInRange(NumberRange(minVal, maxVal));
    int b = _randomInRange(NumberRange(minVal, maxVal));
    int c = _randomInRange(NumberRange(minVal, maxVal));

    // Undvik degenererad data (alla samma).
    for (var i = 0; i < 60; i++) {
      if (!(a == b && b == c)) break;
      b = _randomInRange(NumberRange(minVal, maxVal));
      c = _randomInRange(NumberRange(minVal, maxVal));
    }

    final values = <int>[a, b, c];
    final sorted = _sortedCopy(values);

    // Byggklassning av stapeldiagram med asterisker.
    final diagramLines = <String>[];
    for (int i = 0; i < labels.length; i++) {
      final asterisks = '*' * values[i];
      diagramLines.add('${labels[i]}: $asterisks (${values[i]})');
    }
    final diagram = diagramLines.join('\n');

    final int correct;
    final String questionLine;
    final String explanation;

    if (step <= 7) {
      final maxValEntry = values.reduce((x, y) => x > y ? x : y);
      correct = maxValEntry;
      questionLine = 'Vilket värde är störst?';
      explanation =
          'Jämför alla staplar i diagrammet och välj det största: $correct.';
    } else if (step <= 9) {
      final diff = sorted.last - sorted.first;
      correct = diff;
      questionLine = 'Vad är skillnaden mellan största och minsta värdet?';
      explanation =
          'Skillnad = största - minsta = ${sorted.last} - ${sorted.first} = $correct.';
    } else {
      final sum = values.fold<int>(0, (acc, v) => acc + v);
      if (sum % values.length == 0) {
        correct = sum ~/ values.length;
      } else {
        final remainder = sum % values.length;
        c += (values.length - remainder);
        values[2] = c;
        final adjustedSum = values.fold<int>(0, (acc, v) => acc + v);
        correct = adjustedSum ~/ values.length;
      }
      questionLine = 'Vad är medelvärdet?';
      explanation =
          'Medelvärde = summa / antal = ${values.fold<int>(0, (acc, v) => acc + v)} / ${values.length} = $correct.';
    }

    final prompt = 'Diagram (stapel) = ?\n$diagram\nFråga: $questionLine';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation: explanation,
    );
  }

  Question _generateM4ProbabilityDiagramQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 full (del 2b): sannolikhetsvisualising med färgade bollar i en påse.
    // Visar en enkel grafisk description och frågor om sannolikhet i procent.
    final bag = _pickM4Bag(difficultyStep: difficultyStep);

    final visualization =
        'Påse:\n${_createBallVisualization(bag.red, bag.blue)}';

    final prompt = 'Sannolikhet (diagram) = ?\n$visualization\n'
        'Om du tar en boll slumpmässigt, vad är sannolikheten att få röd?';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: bag.percent,
      wrongAnswers: _generateWrongPercentAnswers(bag.percent, 3),
      promptText: prompt,
      explanation:
          'Röda bollar: ${bag.red}, Totalt: ${bag.total}. Sannolikhet = (${bag.red}/${bag.total}) × 100 = ${bag.percent}%.',
    );
  }

  String _createBallVisualization(int red, int blue) {
    // Skapa en enkel text-visualisering av bollar.
    // Begränsa till max 20 bollar för läsbarhet.
    final totalShown = min(20, red + blue);
    final redShown = (red * totalShown) ~/ (red + blue);
    final blueShown = totalShown - redShown;

    final redBalls = '🔴' * redShown;
    final blueBalls = '🔵' * blueShown;
    return '$redBalls $blueBalls (Röda: $red, Blå: $blue)';
  }

  Question _generateM4MeasurementUnitQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 full (del 3a): enhetskonverteringar — längd, volym, tid.
    final conversionTypes = <String, Map<String, dynamic>>{
      'längd_cm_dm': {'from': 'cm', 'to': 'dm', 'factor': 10, 'range': (2, 60)},
      'längd_m_cm': {'from': 'm', 'to': 'cm', 'factor': 100, 'range': (1, 20)},
      'längd_dm_cm': {'from': 'dm', 'to': 'cm', 'factor': 10, 'range': (3, 50)},
      'volym_ml_cl': {
        'from': 'ml',
        'to': 'cl',
        'factor': 10,
        'range': (10, 100),
      },
      'volym_cl_l': {
        'from': 'cl',
        'to': 'l',
        'factor': 100,
        'range': (50, 500),
      },
      'volym_l_ml': {'from': 'l', 'to': 'ml', 'factor': 1000, 'range': (1, 10)},
      'tid_min_s': {'from': 'min', 'to': 's', 'factor': 60, 'range': (2, 10)},
      'tid_h_min': {'from': 'h', 'to': 'min', 'factor': 60, 'range': (1, 12)},
    };

    final typeKey =
        conversionTypes.keys.toList()[_random.nextInt(conversionTypes.length)];
    final convType = conversionTypes[typeKey]!;

    final from = convType['from'] as String;
    final to = convType['to'] as String;
    final factor = convType['factor'] as int;
    final range = convType['range'] as (int, int);

    final inputValue = range.$1 + _random.nextInt(range.$2 - range.$1 + 1);
    final correctAnswer = inputValue * factor;

    final prompt = 'Enhetskonvertering = ?\n$inputValue $from = ? $to';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correctAnswer,
      wrongAnswers: _generateWrongAnswers(correctAnswer, 3),
      promptText: prompt,
      explanation:
          '$inputValue $from = $inputValue × $factor = $correctAnswer $to.',
    );
  }

  Question _generateM4ShapeAreaQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 full (del 3b): area av enkla former (kvadrat, rektangel, triangel).
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final shapeType =
        _random.nextInt(3); // 0: square, 1: rectangle, 2: triangle
    final int correct;
    String prompt;
    String explanation;

    if (shapeType == 0) {
      // Kvadrat: area = sida²
      final side = 2 +
          _random.nextInt(
            step <= 3
                ? 6
                : step <= 6
                    ? 10
                    : 15,
          );
      correct = side * side;
      prompt = 'Area (kvadrat) = ?\nEn kvadrat har sida $side cm. Area = ?';
      explanation = 'Area av kvadrat = sida² = $side × $side = $correct cm².';
    } else if (shapeType == 1) {
      // Rektangel: area = längd × bredd
      final length = 2 +
          _random.nextInt(
            step <= 3
                ? 8
                : step <= 6
                    ? 12
                    : 15,
          );
      final width = 2 +
          _random.nextInt(
            step <= 3
                ? 8
                : step <= 6
                    ? 12
                    : 15,
          );
      correct = length * width;
      prompt =
          'Area (rektangel) = ?\nEn rektangel är $length cm × $width cm. Area = ?';
      explanation =
          'Area av rektangel = längd × bredd = $length × $width = $correct cm².';
    } else {
      // Triangel: area = (bas × höjd) / 2
      final base = 2 +
          _random.nextInt(
            step <= 3
                ? 8
                : step <= 6
                    ? 10
                    : 12,
          );
      final height = 2 +
          _random.nextInt(
            step <= 3
                ? 8
                : step <= 6
                    ? 10
                    : 12,
          );
      correct = (base * height) ~/ 2;
      prompt =
          'Area (triangel) = ?\nEn triangel har bas $base cm och höjd $height cm. Area = ?';
      explanation =
          'Area av triangel = (bas × höjd) / 2 = ($base × $height) / 2 = $correct cm².';
    }

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation: explanation,
    );
  }

  Question _generateM4ShapePerimeterQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 full (del 3c): omkrets av enkla former (kvadrat, rektangel).
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final isSquare = _random.nextBool();
    final int correct;
    String prompt;
    String explanation;

    if (isSquare) {
      // Kvadrat: omkrets = 4 × sida
      final side = 2 +
          _random.nextInt(
            step <= 3
                ? 6
                : step <= 6
                    ? 10
                    : 15,
          );
      correct = 4 * side;
      prompt =
          'Omkrets (kvadrat) = ?\nEn kvadrat har sida $side cm. Omkrets = ?';
      explanation = 'Omkrets av kvadrat = 4 × sida = 4 × $side = $correct cm.';
    } else {
      // Rektangel: omkrets = 2 × (längd + bredd)
      final length = 2 +
          _random.nextInt(
            step <= 3
                ? 8
                : step <= 6
                    ? 12
                    : 15,
          );
      final width = 2 +
          _random.nextInt(
            step <= 3
                ? 8
                : step <= 6
                    ? 12
                    : 15,
          );
      correct = 2 * (length + width);
      prompt =
          'Omkrets (rektangel) = ?\nEn rektangel är $length cm × $width cm. Omkrets = ?';
      explanation =
          'Omkrets av rektangel = 2 × (längd + bredd) = 2 × ($length + $width) = $correct cm.';
    }

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation: explanation,
    );
  }

  Question _generateM4ProbabilityQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M4 (Åk 4–6, quiz-format utan ny UI):
    // - Sannolikhet i procent (heltal 0–100)
    // - Jämförelse av sannolikhet (skillnad i procentenheter)
    // - Enkel kombinatorik (antal kombinationer)
    // Vi inkluderar '=' i prompten för att UI ska dölja operationssymbolen.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final roll = _random.nextDouble();
    if (step <= 3) {
      return roll < 0.75
          ? _generateM4ProbabilityPercentQuestion(
              difficulty,
              difficultyStep: step,
            )
          : _generateM4ProbabilityCompareQuestion(
              difficulty,
              difficultyStep: step,
            );
    }
    if (step <= 6) {
      if (roll < 0.50) {
        return _generateM4ProbabilityPercentQuestion(
          difficulty,
          difficultyStep: step,
        );
      }
      if (roll < 0.80) {
        return _generateM4ProbabilityCompareQuestion(
          difficulty,
          difficultyStep: step,
        );
      }
      return _generateM4CombinatoricsQuestion(difficulty, difficultyStep: step);
    }

    if (roll < 0.40) {
      return _generateM4ProbabilityPercentQuestion(
        difficulty,
        difficultyStep: step,
      );
    }
    if (roll < 0.70) {
      return _generateM4ProbabilityCompareQuestion(
        difficulty,
        difficultyStep: step,
      );
    }
    return _generateM4CombinatoricsQuestion(difficulty, difficultyStep: step);
  }

  ({int total, int red, int blue, int percent}) _pickM4Bag({
    required int difficultyStep,
  }) {
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final denominators = step <= 3
        ? const <int>[2, 4, 5, 10]
        : step <= 6
            ? const <int>[4, 5, 10, 20]
            : const <int>[10, 20, 25, 50, 100];

    final total = denominators[_random.nextInt(denominators.length)];
    var red = 1 + _random.nextInt(total - 1);

    // Ensure percent is an integer.
    for (var i = 0; i < 60; i++) {
      if ((red * 100) % total == 0) break;
      red = 1 + _random.nextInt(total - 1);
    }

    final blue = total - red;
    final percent = (red * 100) ~/ total;
    return (total: total, red: red, blue: blue, percent: percent);
  }

  Question _generateM4ProbabilityPercentQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    final bag = _pickM4Bag(difficultyStep: difficultyStep);

    final prompt =
        'Chans (%) = ?\nRöda: ${bag.red}, Blå: ${bag.blue}, Totalt: ${bag.total}';
    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: bag.percent,
      wrongAnswers: _generateWrongPercentAnswers(bag.percent, 3),
      promptText: prompt,
      explanation:
          'Chans = (gynnsamma / alla) × 100 = (${bag.red} / ${bag.total}) × 100 = ${bag.percent}%.',
    );
  }

  Question _generateM4ProbabilityCompareQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // Skillnad i procentenheter mellan två påsar.
    // Vi vill undvika negativt svar i quiz-UI, så vi säkrar att A >= B.
    var a = _pickM4Bag(difficultyStep: difficultyStep);
    var b = _pickM4Bag(difficultyStep: difficultyStep);

    for (var i = 0; i < 80; i++) {
      if (a.percent != b.percent) break;
      b = _pickM4Bag(difficultyStep: difficultyStep);
    }

    if (b.percent > a.percent) {
      final tmp = a;
      a = b;
      b = tmp;
    }

    final diff = (a.percent - b.percent).clamp(0, 100);
    final prompt = 'Skillnad i chans (procentenheter) = ?\n'
        'Påse A: Röda: ${a.red}, Blå: ${a.blue}, Totalt: ${a.total}\n'
        'Påse B: Röda: ${b.red}, Blå: ${b.blue}, Totalt: ${b.total}';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: diff,
      wrongAnswers: _generateWrongPercentAnswers(diff, 3),
      promptText: prompt,
      explanation:
          'Räkna chans i % för A och B. Skillnad = ${a.percent}% - ${b.percent}% = $diff procentenheter.',
    );
  }

  Question _generateM4CombinatoricsQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // Enkel kombinatorik: antal kombinationer när man väljer 1 sak ur varje
    // kategori (multiplikationsprincipen).
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final maxA = step <= 3
        ? 4
        : step <= 6
            ? 7
            : 10;
    final maxB = step <= 3
        ? 4
        : step <= 6
            ? 8
            : 12;

    final a = 2 + _random.nextInt(max(1, maxA - 1));
    final b = 2 + _random.nextInt(max(1, maxB - 1));
    final combos = a * b;

    final prompt = 'Kombinationer = ?\nTröjor: $a, Byxor: $b';
    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: combos,
      wrongAnswers: _generateWrongAnswers(combos, 3),
      promptText: prompt,
      explanation:
          'Om du väljer 1 tröja och 1 byxa: $a × $b = $combos kombinationer.',
    );
  }

  Question _generateM5aPercentQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M5a (Åk 7–9, utan ny UI): procent i textformat med heltalssvar.
    // Vi håller oss till "x % av y" i första steget.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final percents = step <= 3
        ? const <int>[10, 20, 25, 50]
        : step <= 6
            ? const <int>[5, 10, 20, 25, 50, 75]
            : const <int>[
                1,
                2,
                4,
                5,
                8,
                10,
                12,
                15,
                20,
                25,
                40,
                50,
                60,
                75,
                80,
                90,
              ];

    final percent = percents[_random.nextInt(percents.length)];
    final denominator = 100 ~/ _gcd(100, percent);

    final multiplierMax = step <= 3
        ? 10
        : step <= 6
            ? 30
            : 100;
    final multiplier = 1 + _random.nextInt(multiplierMax);
    final base = denominator * multiplier;
    final correct = (percent * base) ~/ 100;

    final prompt = 'Procent = ?\nVad är $percent% av $base?';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation: '$percent% av $base = ($percent/100) × $base = $correct.',
    );
  }

  Question _generateM5aPowerQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M5a (Åk 8–9, utan ny UI): potenser i textformat med heltalssvar.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final exponent = step <= 3
        ? 2
        : step <= 6
            ? (2 + _random.nextInt(2))
            : (2 + _random.nextInt(3));

    final maxBase = step <= 3
        ? 12
        : step <= 6
            ? 10
            : 8;
    final base = 2 + _random.nextInt(max(1, maxBase - 1));

    final correct = pow(base, exponent).toInt();
    final prompt = 'Potenser = ?\nVad är $base^$exponent?';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation: '$base^$exponent = $correct.',
    );
  }

  Question _generateM5aPrecedenceQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M5a (Åk 7–9, utan ny UI): prioriteringsregler med + och ×,
    // med/utan parenteser beroende på step.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final maxA = step <= 3
        ? 20
        : step <= 6
            ? 40
            : 80;

    final a = 2 + _random.nextInt(maxA - 1);
    final b = 2 + _random.nextInt(maxA - 1);
    final c = 2 + _random.nextInt(maxA - 1);

    final allowParentheses = step >= 5;
    final useParentheses = allowParentheses && _random.nextBool();
    final preferMulFirst = _random.nextBool();

    late final String expression;
    late final int correct;
    late final int commonWrong;

    if (useParentheses) {
      if (preferMulFirst) {
        expression = '($a + $b) × $c';
        correct = (a + b) * c;
        commonWrong = a + (b * c);
      } else {
        expression = '$a × ($b + $c)';
        correct = a * (b + c);
        commonWrong = (a * b) + c;
      }
    } else {
      if (preferMulFirst) {
        expression = '$a + $b × $c';
        correct = a + (b * c);
        commonWrong = (a + b) * c;
      } else {
        expression = '$a × $b + $c';
        correct = (a * b) + c;
        commonWrong = a * (b + c);
      }
    }

    final wrong = <int>{};
    if (commonWrong != correct) {
      wrong.add(commonWrong);
    }
    for (final candidate in _generateWrongAnswers(correct, 6)) {
      if (candidate != correct) {
        wrong.add(candidate);
      }
      if (wrong.length >= 3) break;
    }

    final prompt = 'Prioriteringsregler = ?\n$expression';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: wrong.take(3).toList(),
      promptText: prompt,
      explanation:
          'Räkna multiplikation före addition, och räkna alltid parenteser först.',
    );
  }

  Question _generateM5bLinearFunctionQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M5b (Åk 7–9, introduktion till visualiserad matematik): linjära funktioner
    // i textformat med koordinatvisualisering.
    // Formatet är y = mx + b, där vi ber eleverna beräkna y för ett givet x.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final maxSlope = step <= 3
        ? 3
        : step <= 6
            ? 5
            : 10;
    final slope = 1 + _random.nextInt(maxSlope);

    final maxIntercept = step <= 3
        ? 5
        : step <= 6
            ? 10
            : 20;
    final intercept = _random.nextInt(2 * maxIntercept + 1) - maxIntercept;

    final maxX = step <= 3
        ? 5
        : step <= 6
            ? 10
            : 20;
    final testX = 1 + _random.nextInt(maxX);

    final correct = slope * testX + intercept;

    // Skapa en enkel koordinatvisualisering med några punkter för att hjälpa
    // eleverna att förstå funktionen visuellt.
    final coordinatePoints = <String>[];
    for (int x = 0; x <= min(3, testX); x++) {
      final y = slope * x + intercept;
      coordinatePoints.add('  x=$x, y=$y');
    }
    final coordinateList = coordinatePoints.join('\n');

    final prompt = '''Linjär funktion = ?
y = ${slope}x + $intercept

Koordinater:
$coordinateList

Beräkna y när x = $testX''';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correct,
      wrongAnswers: _generateWrongAnswers(correct, 3),
      promptText: prompt,
      explanation:
          'y = $slope x + $intercept\ny = $slope ×$testX + $intercept = $correct',
    );
  }

  Question _generateM5bGeometricTransformationQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M5b (Åk 7–9, delstep 2): Geometriska transformationer
    // Spegling, rotation och translation i koordinatsystem.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    // Välj transformationstyp
    final maxCoord = step <= 3
        ? 10
        : step <= 6
            ? 15
            : 20;

    final beforeX = _random.nextInt(maxCoord + 1) - (maxCoord ~/ 2);
    final beforeY = _random.nextInt(maxCoord + 1) - (maxCoord ~/ 2);

    // Undvik (0, 0)
    if (beforeX == 0 && beforeY == 0) {
      return _generateM5bGeometricTransformationQuestion(
        difficulty,
        difficultyStep: difficultyStep,
      );
    }

    final transformType = _random.nextInt(6); // 0-5 för 6 transformationer

    late final int afterX;
    late final int afterY;
    late final String transformName;
    late final String axis;
    late final int answerValue;
    late final String answerType;

    switch (transformType) {
      case 0:
        // Spegling över x-axel: (x, y) → (x, -y)
        afterX = beforeX;
        afterY = -beforeY;
        transformName = 'Spegling över x-axel';
        axis = '(horisontell linje)';
        answerValue = afterY;
        answerType = 'y-värde';
        break;
      case 1:
        // Spegling över y-axel: (x, y) → (-x, y)
        afterX = -beforeX;
        afterY = beforeY;
        transformName = 'Spegling över y-axel';
        axis = '(vertikal linje)';
        answerValue = afterX;
        answerType = 'x-värde';
        break;
      case 2:
        // Spegling över y=x (diagonal): (x, y) → (y, x)
        afterX = beforeY;
        afterY = beforeX;
        transformName = 'Spegling över diagonalen y=x';
        axis = '(diagonal)';
        answerValue = afterY;
        answerType = 'y-värde';
        break;
      case 3:
        // Rotation 90° moturs runt origo: (x, y) → (-y, x)
        afterX = -beforeY;
        afterY = beforeX;
        transformName = 'Rotation 90° moturs';
        axis = '(moturs runt origo)';
        answerValue = afterX;
        answerType = 'x-värde';
        break;
      case 4:
        // Rotation 180° runt origo: (x, y) → (-x, -y)
        afterX = -beforeX;
        afterY = -beforeY;
        transformName = 'Rotation 180°';
        axis = '(runt origo)';
        answerValue = afterY;
        answerType = 'y-värde';
        break;
      case 5:
        // Translation: (x, y) → (x+dx, y+dy)
        final dx = _random.nextInt(10) - 5; // -5 till 4
        final dy = _random.nextInt(10) - 5;
        afterX = beforeX + dx;
        afterY = beforeY + dy;
        transformName = 'Translation (förflyttning)';
        axis = 'förskjutning ($dx, $dy)';
        // För translation frågar vi bara efter ett värde
        answerValue = _random.nextBool() ? afterX : afterY;
        answerType = _random.nextBool() ? 'x-värde' : 'y-värde';
        break;
    }

    final prompt = '''Geometrisk transformation = ?
Transformation: $transformName $axis
Punkt före: ($beforeX, $beforeY)
Punkt efter: ($afterX, $afterY)

Vad är $answerType efter transformationen?''';

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: answerValue,
      wrongAnswers: _generateWrongAnswers(answerValue, 3),
      promptText: prompt,
      explanation:
          '$transformName: ($beforeX, $beforeY) → ($afterX, $afterY)\nSvar: $answerType Efter transformationen är det $answerValue',
    );
  }

  Question _generateM5bAdvancedStatisticsQuestion(
    DifficultyLevel difficulty, {
    required int difficultyStep,
  }) {
    // M5b (Åk 7–9, delstep 3): Avancerad statistik
    // Distributioner, outliers och korrelationer i textformat.
    final step = DifficultyConfig.clampDifficultyStep(difficultyStep);

    final questionType =
        _random.nextInt(3); // 0=outlier, 1=distribution, 2=correlation

    late final String prompt;
    late final int correctAnswer;

    if (questionType == 0) {
      // Outlier-fråga: identifiera värdet som avviker mycket
      final dataSize = step <= 3
          ? 5
          : step <= 6
              ? 7
              : 9;
      final baseValue = 10 + _random.nextInt(30);
      final variance = step <= 3
          ? 2
          : step <= 6
              ? 3
              : 4;

      final data = <int>[];
      for (int i = 0; i < dataSize - 1; i++) {
        final val = baseValue + _random.nextInt(2 * variance + 1) - variance;
        data.add(max(1, val));
      }

      // Lägg till en tydlig outlier
      final outlier = baseValue + (10 + _random.nextInt(20));
      data.add(outlier);
      data.shuffle(_random);

      final dataStr = data.join(', ');
      correctAnswer = outlier;

      prompt = '''Statistik = ?
Datasätt: $dataStr

Vilket värde är en outlier (avviker mycket från övriga)?''';
    } else if (questionType == 1) {
      // Distribution-fråga: ge ett datasätt och fråga om mode (vanligaste värde)
      final dataSize = step <= 3
          ? 6
          : step <= 6
              ? 8
              : 10;
      final mode = 5 + _random.nextInt(15);

      final data = <int>[];
      // Lägg till mode flera gånger
      final modeCount = step <= 3
          ? 2
          : step <= 6
              ? 2
              : 3;
      for (int i = 0; i < modeCount; i++) {
        data.add(mode);
      }

      // Lägg till andra värden
      for (int i = data.length; i < dataSize; i++) {
        var val = 5 + _random.nextInt(20);
        while (val == mode && i < dataSize - 1) {
          val = 5 + _random.nextInt(20);
        }
        data.add(val);
      }
      data.shuffle(_random);

      final dataStr = data.join(', ');
      correctAnswer = mode;

      prompt = '''Statistik = ?
Datasätt: $dataStr

Vad är typvärdet (det värde som förekommer oftast)?''';
    } else {
      // Korrelation-fråga: två variabler och fråga om de är positivt/negativt korrelerade
      // Vi kodar svaret som: 1 = positiv korrelation, -1 = negativ korrelation
      final isPositive = _random.nextBool();

      final var1Values = <int>[];
      final var2Values = <int>[];

      final dataSize = step <= 3
          ? 4
          : step <= 6
              ? 5
              : 6;
      for (int i = 0; i < dataSize; i++) {
        final x = 10 + i * 5 + _random.nextInt(3);
        var1Values.add(x);

        if (isPositive) {
          // Positivt korrelerad: y ökar när x ökar
          var2Values.add(x + _random.nextInt(10) - 2);
        } else {
          // Negativt korrelerad: y minskar när x ökar
          var2Values.add(50 - x + _random.nextInt(10) - 5);
        }
      }

      final var1Str = var1Values.join(', ');
      final var2Str = var2Values.join(', ');
      correctAnswer = isPositive ? 1 : -1;

      final prompt1 = '''Statistik = ?
Variabel A: $var1Str
Variabel B: $var2Str

Vilken typ av korrelation har variablerna?
(Svar: 1 för positiv, -1 för negativ)''';

      prompt = prompt1;
    }

    return Question(
      id: _uuid.v4(),
      operationType: OperationType.mixed,
      difficulty: difficulty,
      operand1: 0,
      operand2: 0,
      correctAnswer: correctAnswer,
      wrongAnswers: _generateWrongAnswers(correctAnswer, 3),
      promptText: prompt,
      explanation:
          'Analysera datasättets egenskaper: outliers är värden långt från genomsnittet, typvärde är det vanligaste värdet, och korrelation beskriver sambandet mellan variabler.',
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
    final isM5aGrade = gradeLevel != null && gradeLevel >= 7 && gradeLevel <= 9;
    final avoidCarryAllDigits = isM3Grade && difficultyStep <= 3;
    final requireCarrySomewhere = isM3Grade && difficultyStep >= 8;

    int operand1;
    int operand2;

    // Åk 7–9 (M5a): allow signed operands and answers.
    if (isM5aGrade) {
      final maxAbs = difficultyStep <= 3
          ? min(20, max(1, range.max))
          : difficultyStep <= 6
              ? min(100, max(1, range.max))
              : min(1000, max(1, range.max));

      operand1 = _randomSignedValue(maxAbs);
      operand2 = _randomSignedValue(maxAbs);
      if (operand1 == 0 && operand2 == 0) {
        operand2 = 1;
      }
    }
    // Bias: tiokompisar in Åk 1 when range allows.
    else if (isGrade1 && range.max >= 10 && _random.nextDouble() < 0.35) {
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
      wrongAnswers: _generateWrongAnswers(
        correctAnswer,
        3,
        allowNegative: isM5aGrade,
      ),
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
    final isM5aGrade = gradeLevel != null && gradeLevel >= 7 && gradeLevel <= 9;
    final avoidBorrowAllDigits = isM3Grade && difficultyStep <= 3;
    final requireBorrowSomewhere = isM3Grade && difficultyStep >= 8;

    var operand1 = _randomInRange(range);
    var operand2 = _randomInRange(range);

    if (isM5aGrade) {
      final maxAbs = difficultyStep <= 3
          ? min(20, max(1, range.max))
          : difficultyStep <= 6
              ? min(100, max(1, range.max))
              : min(1000, max(1, range.max));

      operand1 = _randomSignedValue(maxAbs);
      // Keep operand2 positive/non-zero to avoid "a - -b" at this stage.
      operand2 = _randomInRange(NumberRange(1, maxAbs));
    } else if (isGrade1 && range.max >= 10 && _random.nextDouble() < 0.35) {
      operand1 = 10;
      operand2 = _randomInRange(const NumberRange(0, 10));
    }

    for (var i = 0; i < 120; i++) {
      if (!isM5aGrade && operand2 > operand1) {
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
      wrongAnswers: _generateWrongAnswers(
        correctAnswer,
        3,
        allowNegative: isM5aGrade,
      ),
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

  List<int> _generateWrongAnswers(
    int correctAnswer,
    int count, {
    bool allowNegative = false,
  }) {
    final wrongAnswers = <int>{};
    final spread = max(10, correctAnswer.abs() ~/ 2);

    while (wrongAnswers.length < count) {
      var wrongAnswer = correctAnswer + _random.nextInt(spread * 2) - spread;

      // For younger grades we keep options non-negative.
      if (!allowNegative && wrongAnswer < 0) wrongAnswer = -wrongAnswer;
      if (wrongAnswer == correctAnswer) continue;

      wrongAnswers.add(wrongAnswer);
    }

    return wrongAnswers.toList();
  }

  /// M4a: Tid (klockan) för Åk 1–3
  /// Åk 1: hel/halv timme
  /// Åk 2: + kvart
  /// Åk 3: alla minuter + tidsintervall
  Question _generateM4TimeQuestion(
    DifficultyLevel difficulty, {
    required int gradeLevel,
    required int difficultyStep,
  }) {
    final isGrade1 = gradeLevel == 1;
    final isGrade2 = gradeLevel == 2;
    final isGrade3 = gradeLevel == 3;

    // Åk 1: Endast hel och halv timme
    if (isGrade1) {
      final isHalfHour = _random.nextBool();
      final hour = 1 + _random.nextInt(12); // 1-12
      final minute = isHalfHour ? 30 : 0;

      final timeStr = '$hour:${minute.toString().padLeft(2, '0')}';

      if (minute == 0) {
        // Hel timme: fråga vilken timme
        final prompt = 'Klockan visar $timeStr.\n\nVilken timme är det?';
        return Question(
          id: _uuid.v4(),
          operationType: OperationType.mixed,
          difficulty: difficulty,
          operand1: 0,
          operand2: 0,
          correctAnswer: hour,
          wrongAnswers: _generateWrongAnswers(hour, 3)
              .map((w) => w.clamp(1, 12))
              .toSet()
              .toList(),
          promptText: prompt,
          explanation: 'Klockan $timeStr betyder att timmen är $hour.',
        );
      } else {
        // Halv timme: fråga minuter efter hel timme
        final prompt =
            'Klockan visar $timeStr.\n\nHur många minuter efter $hour?';
        return Question(
          id: _uuid.v4(),
          operationType: OperationType.mixed,
          difficulty: difficulty,
          operand1: 0,
          operand2: 0,
          correctAnswer: 30,
          wrongAnswers: [15, 45, 0].where((w) => w != 30).take(3).toList(),
          promptText: prompt,
          explanation:
              'Klockan $timeStr betyder att det är 30 minuter efter $hour.',
        );
      }
    }

    // Åk 2: Hel, halv och kvart
    if (isGrade2) {
      final hour = 1 + _random.nextInt(12);
      final minuteOptions = [0, 15, 30, 45];
      final minute = minuteOptions[_random.nextInt(minuteOptions.length)];

      final timeStr = '$hour:${minute.toString().padLeft(2, '0')}';

      if (minute == 0) {
        final prompt = 'Klockan visar $timeStr.\n\nVilken timme är det?';
        return Question(
          id: _uuid.v4(),
          operationType: OperationType.mixed,
          difficulty: difficulty,
          operand1: 0,
          operand2: 0,
          correctAnswer: hour,
          wrongAnswers: _generateWrongAnswers(hour, 3)
              .map((w) => w.clamp(1, 12))
              .toSet()
              .toList(),
          promptText: prompt,
          explanation: 'Klockan $timeStr betyder att timmen är $hour.',
        );
      } else {
        final prompt =
            'Klockan visar $timeStr.\n\nHur många minuter efter $hour?';
        return Question(
          id: _uuid.v4(),
          operationType: OperationType.mixed,
          difficulty: difficulty,
          operand1: 0,
          operand2: 0,
          correctAnswer: minute,
          wrongAnswers:
              minuteOptions.where((w) => w != minute).take(3).toList(),
          promptText: prompt,
          explanation:
              'Klockan $timeStr betyder att det är $minute minuter efter $hour.',
        );
      }
    }

    // Åk 3: Alla minuter (5-minutersintervall) + tidsintervall
    if (isGrade3) {
      final useInterval = difficultyStep >= 5 && _random.nextBool();

      if (useInterval) {
        // Tidsintervall: "Klockan var X:YY och blev Z:WW. Hur många minuter?"
        final startHour = 8 + _random.nextInt(4); // 8-11
        final startMinute = _random.nextInt(12) * 5; // 0, 5, 10, ..., 55

        final durationMinutes = 10 + _random.nextInt(90); // 10-99 minuter
        final totalStartMinutes = startHour * 60 + startMinute;
        final totalEndMinutes = totalStartMinutes + durationMinutes;

        final endHour = (totalEndMinutes ~/ 60) % 24;
        final endMinute = totalEndMinutes % 60;

        final startTimeStr =
            '$startHour:${startMinute.toString().padLeft(2, '0')}';
        final endTimeStr = '$endHour:${endMinute.toString().padLeft(2, '0')}';

        final prompt =
            'Klockan var $startTimeStr.\nSen blev klockan $endTimeStr.\n\nHur många minuter gick?';

        return Question(
          id: _uuid.v4(),
          operationType: OperationType.mixed,
          difficulty: difficulty,
          operand1: 0,
          operand2: 0,
          correctAnswer: durationMinutes,
          wrongAnswers: _generateWrongAnswers(durationMinutes, 3),
          promptText: prompt,
          explanation:
              'Från $startTimeStr till $endTimeStr är det $durationMinutes minuter.',
        );
      } else {
        // Enkel tid med minuter
        final hour = 6 + _random.nextInt(10); // 6-15
        final minute = _random.nextInt(12) * 5; // 0, 5, 10, ..., 55

        final timeStr = '$hour:${minute.toString().padLeft(2, '0')}';

        if (minute == 0) {
          final prompt = 'Klockan visar $timeStr.\n\nVilken timme är det?';
          return Question(
            id: _uuid.v4(),
            operationType: OperationType.mixed,
            difficulty: difficulty,
            operand1: 0,
            operand2: 0,
            correctAnswer: hour,
            wrongAnswers: _generateWrongAnswers(hour, 3)
                .map((w) => w.clamp(1, 23))
                .toSet()
                .toList(),
            promptText: prompt,
            explanation: 'Klockan $timeStr betyder att timmen är $hour.',
          );
        } else {
          final prompt =
              'Klockan visar $timeStr.\n\nHur många minuter efter $hour?';
          return Question(
            id: _uuid.v4(),
            operationType: OperationType.mixed,
            difficulty: difficulty,
            operand1: 0,
            operand2: 0,
            correctAnswer: minute,
            wrongAnswers: _generateWrongAnswers(minute, 3)
                .map((w) => w.clamp(0, 55))
                .toSet()
                .toList(),
            promptText: prompt,
            explanation:
                'Klockan $timeStr betyder att det är $minute minuter efter $hour.',
          );
        }
      }
    }

    // Fallback (bör inte hända)
    return _generateM4TimeQuestion(
      difficulty,
      gradeLevel: 1,
      difficultyStep: difficultyStep,
    );
  }
}
