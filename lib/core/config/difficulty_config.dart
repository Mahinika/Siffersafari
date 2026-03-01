import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';

/// Configuration for difficulty levels based on age groups
class DifficultyConfig {
  DifficultyConfig._();

  /// Target success rate for "lagom" difficulty.
  ///
  /// Heuristic: aim for a high-but-not-perfect success rate.
  static const double trainingTargetSuccessRate = 0.85;

  /// Window size for the parent dashboard recommendation.
  static const int trainingRecommendationWindow = 3;

  /// Simple benchmark result used for parent feedback.
  ///
  /// This is a lightweight, app-internal indicator (not a formal assessment).
  static const int _benchmarkInlineTolerance = 2;

  static int expectedDifficultyStepForGrade({
    required int gradeLevel,
    required OperationType operation,
  }) {
    final grade = gradeLevel.clamp(1, 9);

    // Keep it conservative and predictable:
    // - Åk 1–2: focus on +/−; ×/÷ are expected to be very low.
    // - Åk 3: all four operations included, still gentle for ×/÷.
    // - Åk 4–6: ramp up steadily.
    // - Åk 7–9: higher expectations.
    final isMulDiv = operation == OperationType.multiplication ||
        operation == OperationType.division;

    if (grade <= 2) {
      return isMulDiv ? 1 : 2;
    }

    if (grade == 3) {
      return isMulDiv ? 2 : 3;
    }

    if (grade <= 6) {
      return isMulDiv ? 4 : 5;
    }

    return isMulDiv ? 6 : 7;
  }

  static GradeBenchmark compareDifficultyStepToGrade({
    required int gradeLevel,
    required OperationType operation,
    required int difficultyStep,
  }) {
    final expected = expectedDifficultyStepForGrade(
      gradeLevel: gradeLevel,
      operation: operation,
    );
    final actual = clampDifficultyStep(difficultyStep);
    final delta = actual - expected;

    if (delta <= -(_benchmarkInlineTolerance + 1)) {
      return GradeBenchmark(
        expectedStep: expected,
        actualStep: actual,
        delta: delta,
        level: GradeBenchmarkLevel.under,
      );
    }

    if (delta >= (_benchmarkInlineTolerance + 1)) {
      return GradeBenchmark(
        expectedStep: expected,
        actualStep: actual,
        delta: delta,
        level: GradeBenchmarkLevel.over,
      );
    }

    return GradeBenchmark(
      expectedStep: expected,
      actualStep: actual,
      delta: delta,
      level: GradeBenchmarkLevel.inline,
    );
  }

  static String benchmarkLevelLabel(GradeBenchmarkLevel level) {
    switch (level) {
      case GradeBenchmarkLevel.under:
        return 'Under';
      case GradeBenchmarkLevel.inline:
        return 'I linje';
      case GradeBenchmarkLevel.over:
        return 'Över';
    }
  }

  static String benchmarkRecommendationText({
    required GradeBenchmarkLevel level,
    required OperationType operation,
  }) {
    // Keep this short, actionable, and clearly non-judgmental.
    // The indicator is heuristic; this is just a practical next step.
    final isMulDiv = operation == OperationType.multiplication ||
        operation == OperationType.division;

    switch (level) {
      case GradeBenchmarkLevel.under:
        if (!isMulDiv) {
          return operation == OperationType.subtraction
              ? 'Öva 3–5 min: minus med små tal (t.ex. upp till 10–20).'
              : 'Öva 3–5 min: plus med små tal (t.ex. upp till 10–20).';
        }
        return operation == OperationType.division
            ? 'Öva 3–5 min: delat med små tal (t.ex. 10÷2, 12÷3).'
            : 'Öva 3–5 min: gångertabeller (t.ex. 2, 5, 10).';
      case GradeBenchmarkLevel.inline:
        return '';
      case GradeBenchmarkLevel.over:
        return 'Om det känns lätt kan du låta appen höja svårigheten gradvis.';
    }
  }

  /// Suggests how many steps (1..3) to adjust when a parent taps
  /// "Lättare" / "Svårare".
  ///
  /// Idea: small tweaks by default, but allow bigger corrections when the
  /// child is clearly far from the grade expectation and the tap moves
  /// towards that expectation.
  static int parentSuggestedAdjustmentSteps({
    required GradeBenchmark benchmark,
    required bool makeHarder,
  }) {
    // If parent moves *against* the indicator, stay cautious.
    final towardsExpected =
        (benchmark.level == GradeBenchmarkLevel.under && makeHarder) ||
            (benchmark.level == GradeBenchmarkLevel.over && !makeHarder);
    if (!towardsExpected) return 1;

    final distance = benchmark.delta.abs();
    if (distance >= 5) return 3;
    if (distance >= 3) return 2;
    return 1;
  }

  /// A minimal, child-facing mapping for which operations to show by grade (Åk).
  ///
  /// Parent settings are still the hard limit; this mapping only further
  /// constrains what the child sees when a grade is set.
  ///
  /// Note: Skolverket's central content for Åk 1–3 includes the four operations,
  /// but many children benefit from a gentler progression early on.
  static Set<OperationType> visibleOperationsForGrade(int gradeLevel) {
    final grade = gradeLevel.clamp(1, 9);

    // Keep early grades focused (avoid overwhelming choice).
    if (grade <= 2) {
      return const {
        OperationType.addition,
        OperationType.subtraction,
      };
    }

    // Åk 3: include all four operations (Skolverket: "de fyra räknesätten").
    if (grade == 3) {
      return const {
        OperationType.addition,
        OperationType.subtraction,
        OperationType.multiplication,
        OperationType.division,
      };
    }

    return const {
      OperationType.addition,
      OperationType.subtraction,
      OperationType.multiplication,
      OperationType.division,
    };
  }

  /// Intersects [parentAllowedOperations] with [visibleOperationsForGrade] when
  /// [gradeLevel] is set. If the intersection would be empty (e.g. parent has
  /// disabled the recommended ops), we fall back to the parent set.
  static Set<OperationType> effectiveAllowedOperations({
    required Set<OperationType> parentAllowedOperations,
    required int? gradeLevel,
  }) {
    final grade = gradeLevel;
    if (grade == null) return parentAllowedOperations;

    final byGrade = visibleOperationsForGrade(grade);
    final intersection = parentAllowedOperations.intersection(byGrade);
    return intersection.isEmpty ? parentAllowedOperations : intersection;
  }

  /// Internal difficulty steps used for smoother progression.
  ///
  /// UI still exposes [DifficultyLevel], but internally we can use 10 steps
  /// and map them onto the existing easy/medium/hard ranges.
  static const int minDifficultyStep = 1;
  static const int maxDifficultyStep = 10;

  static int clampDifficultyStep(int step) {
    return step.clamp(minDifficultyStep, maxDifficultyStep);
  }

  /// Grade-aware range for question generation.
  ///
  /// This uses a conservative interpretation of typical Swedish progression:
  /// - Åk1: mostly within 0–20 for +/−.
  /// - Åk2: within 0–100 for +/−, and small ×/÷ if enabled by parent.
  /// - Åk3: within 0–1000 for +/−, and times tables.
  ///
  /// Higher grades are mapped to larger caps, but the app currently generates
  /// integer-only arithmetic (no negatives/decimals/bråk yet).
  static NumberRange curriculumNumberRangeForStep({
    required int gradeLevel,
    required OperationType operationType,
    required int difficultyStep,
  }) {
    final grade = gradeLevel.clamp(1, 9);
    final step = clampDifficultyStep(difficultyStep);
    final t =
        (step - minDifficultyStep) / (maxDifficultyStep - minDifficultyStep);

    int cap;
    switch (operationType) {
      case OperationType.addition:
      case OperationType.subtraction:
        cap = switch (grade) {
          1 => 20,
          2 => 100,
          3 => 1000,
          4 => 10000,
          5 => 100000,
          _ => 1000000,
        };
      case OperationType.multiplication:
      case OperationType.division:
      case OperationType.mixed:
        cap = switch (grade) {
          1 => 5,
          2 => 10,
          3 => 12,
          4 => 20,
          5 => 30,
          _ => 60,
        };
    }

    final startMax = switch (operationType) {
      OperationType.addition || OperationType.subtraction => 10,
      _ => 5,
    };

    final safeStart = startMax > cap ? cap : startMax;
    final maxVal = _lerpInt(safeStart, cap, t);
    return NumberRange(0, maxVal);
  }

  /// Recommends a difficulty step for training based on recent results.
  ///
  /// This is intentionally stable and uses small step changes.
  ///
  /// Returns null when [averageSuccessRate] is null (no data).
  static int? recommendedDifficultyStepForTraining({
    required int currentStep,
    required double? averageSuccessRate,
    double targetSuccessRate = trainingTargetSuccessRate,
  }) {
    final avg = averageSuccessRate;
    if (avg == null) return null;

    final step = clampDifficultyStep(currentStep);
    final rate = avg.clamp(0.0, 1.0);

    // Tuned around the 85% target:
    // - If clearly above target -> suggest harder.
    // - If clearly below target -> suggest easier.
    // - Otherwise -> keep.
    const eps = 1e-9;
    final harder2 = targetSuccessRate + 0.10;
    final harder1 = targetSuccessRate + 0.05;
    final easier2 = targetSuccessRate - 0.15;
    final easier1 = targetSuccessRate - 0.05;

    final delta = rate >= harder2 - eps
        ? 2
        : rate >= harder1 - eps
            ? 1
            : rate <= easier2 + eps
                ? -2
                : rate <= easier1 + eps
                    ? -1
                    : 0;

    return clampDifficultyStep(step + delta);
  }

  /// Default starting step if no stored history exists.
  static int initialStepForDifficulty(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 2;
      case DifficultyLevel.medium:
        return 5;
      case DifficultyLevel.hard:
        return 8;
    }
  }

  /// Builds a complete step map (for all non-mixed operations) using stored
  /// values when present, otherwise falling back to an initial step derived
  /// from [defaultDifficulty].
  static Map<OperationType, int> buildDifficultySteps({
    required Map<String, int> storedSteps,
    required DifficultyLevel defaultDifficulty,
    bool preferEasyStart = true,
  }) {
    // Default: start conservatively (too easy > too hard). If we have stored
    // history, that always wins.
    final fallback = preferEasyStart
        ? clampDifficultyStep(2)
        : initialStepForDifficulty(defaultDifficulty);
    return {
      OperationType.addition: clampDifficultyStep(
        storedSteps[OperationType.addition.name] ?? fallback,
      ),
      OperationType.subtraction: clampDifficultyStep(
        storedSteps[OperationType.subtraction.name] ?? fallback,
      ),
      OperationType.multiplication: clampDifficultyStep(
        storedSteps[OperationType.multiplication.name] ?? fallback,
      ),
      OperationType.division: clampDifficultyStep(
        storedSteps[OperationType.division.name] ?? fallback,
      ),
    };
  }

  static int _lerpInt(int a, int b, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return (a + (b - a) * clampedT).round();
  }

  /// Step-based number range that smoothly interpolates between the existing
  /// easy/medium/hard ranges.
  static NumberRange getNumberRangeForStep(
    AgeGroup ageGroup,
    OperationType operationType,
    int difficultyStep,
  ) {
    final step = clampDifficultyStep(difficultyStep);
    final rangeEasy =
        getNumberRange(ageGroup, operationType, DifficultyLevel.easy);
    final rangeMedium =
        getNumberRange(ageGroup, operationType, DifficultyLevel.medium);
    final rangeHard =
        getNumberRange(ageGroup, operationType, DifficultyLevel.hard);

    // Map 1..10 -> 0..1.
    final t =
        (step - minDifficultyStep) / (maxDifficultyStep - minDifficultyStep);

    // Piecewise lerp: easy->medium for t in [0, 0.5), medium->hard for [0.5, 1].
    final NumberRange a;
    final NumberRange b;
    final double localT;
    if (t < 0.5) {
      a = rangeEasy;
      b = rangeMedium;
      localT = t / 0.5;
    } else {
      a = rangeMedium;
      b = rangeHard;
      localT = (t - 0.5) / 0.5;
    }

    final minVal = _lerpInt(a.min, b.min, localT);
    final maxVal = _lerpInt(a.max, b.max, localT);
    if (maxVal >= minVal) {
      return NumberRange(minVal, maxVal);
    }
    return NumberRange(maxVal, minVal);
  }

  /// When a grade (Åk) is selected, we map it to a coarse age group plus a
  /// difficulty level. This allows the app to keep a per-grade progression
  /// without introducing a second, parallel range system.
  static AgeGroup effectiveAgeGroup({
    required AgeGroup fallback,
    required int? gradeLevel,
  }) {
    final grade = gradeLevel;
    if (grade == null) return fallback;

    if (grade <= 3) return AgeGroup.young;
    if (grade <= 6) return AgeGroup.middle;
    return AgeGroup.older;
  }

  /// Returns the grade-mapped difficulty, or [fallback] if no grade is set.
  ///
  /// Mapping: Åk1-3 => easy/medium/hard, Åk4-6 => easy/medium/hard,
  /// Åk7-9 => easy/medium/hard.
  static DifficultyLevel effectiveDifficulty({
    required DifficultyLevel fallback,
    required int? gradeLevel,
  }) {
    final grade = gradeLevel;
    if (grade == null) return fallback;

    final bucket = ((grade - 1) % 3) + 1; // 1..3
    switch (bucket) {
      case 1:
        return DifficultyLevel.easy;
      case 2:
        return DifficultyLevel.medium;
      default:
        return DifficultyLevel.hard;
    }
  }

  /// Get number range for a specific age group, operation, and difficulty
  static NumberRange getNumberRange(
    AgeGroup ageGroup,
    OperationType operationType,
    DifficultyLevel difficulty,
  ) {
    // Based on educational research (see plan document)
    switch (ageGroup) {
      case AgeGroup.young: // 6-8 years
        return _getYoungRange(operationType, difficulty);
      case AgeGroup.middle: // 8-10 years
        return _getMiddleRange(operationType, difficulty);
      case AgeGroup.older: // 10-13 years
        return _getOlderRange(operationType, difficulty);
    }
  }

  static NumberRange _getYoungRange(
    OperationType operation,
    DifficultyLevel difficulty,
  ) {
    switch (operation) {
      case OperationType.addition:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 10);
          case DifficultyLevel.medium:
            return const NumberRange(0, 20);
          case DifficultyLevel.hard:
            return const NumberRange(0, 50);
        }
      case OperationType.subtraction:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 10);
          case DifficultyLevel.medium:
            return const NumberRange(0, 20);
          case DifficultyLevel.hard:
            return const NumberRange(0, 50);
        }
      case OperationType.multiplication:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 5);
          case DifficultyLevel.medium:
            return const NumberRange(0, 10);
          case DifficultyLevel.hard:
            return const NumberRange(0, 12);
        }
      case OperationType.division:
        // Note: used for quotient + divisor (dividend becomes divisor * quotient)
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 5);
          case DifficultyLevel.medium:
            return const NumberRange(0, 10);
          case DifficultyLevel.hard:
            return const NumberRange(0, 12);
        }
      case OperationType.mixed:
        // Keep mixed conservative to avoid huge operands for × and ÷
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 5);
          case DifficultyLevel.medium:
            return const NumberRange(0, 10);
          case DifficultyLevel.hard:
            return const NumberRange(0, 12);
        }
    }
  }

  static NumberRange _getMiddleRange(
    OperationType operation,
    DifficultyLevel difficulty,
  ) {
    switch (operation) {
      case OperationType.addition:
      case OperationType.subtraction:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 100);
          case DifficultyLevel.medium:
            return const NumberRange(0, 500);
          case DifficultyLevel.hard:
            return const NumberRange(0, 1000);
        }
      case OperationType.multiplication:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 12);
          case DifficultyLevel.medium:
            return const NumberRange(0, 20);
          case DifficultyLevel.hard:
            return const NumberRange(0, 30);
        }
      case OperationType.division:
        // Note: used for quotient + divisor (dividend becomes divisor * quotient)
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 12);
          case DifficultyLevel.medium:
            return const NumberRange(0, 20);
          case DifficultyLevel.hard:
            return const NumberRange(0, 30);
        }
      case OperationType.mixed:
        // Keep mixed conservative to avoid huge operands for × and ÷
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 12);
          case DifficultyLevel.medium:
            return const NumberRange(0, 20);
          case DifficultyLevel.hard:
            return const NumberRange(0, 30);
        }
    }
  }

  static NumberRange _getOlderRange(
    OperationType operation,
    DifficultyLevel difficulty,
  ) {
    switch (operation) {
      case OperationType.addition:
      case OperationType.subtraction:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 1000);
          case DifficultyLevel.medium:
            return const NumberRange(0, 5000);
          case DifficultyLevel.hard:
            return const NumberRange(0, 10000);
        }
      case OperationType.multiplication:
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 15);
          case DifficultyLevel.medium:
            return const NumberRange(0, 30);
          case DifficultyLevel.hard:
            return const NumberRange(0, 60);
        }
      case OperationType.division:
        // Note: used for quotient + divisor (dividend becomes divisor * quotient)
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 15);
          case DifficultyLevel.medium:
            return const NumberRange(0, 30);
          case DifficultyLevel.hard:
            return const NumberRange(0, 60);
        }
      case OperationType.mixed:
        // Keep mixed conservative to avoid huge operands for × and ÷
        switch (difficulty) {
          case DifficultyLevel.easy:
            return const NumberRange(0, 15);
          case DifficultyLevel.medium:
            return const NumberRange(0, 30);
          case DifficultyLevel.hard:
            return const NumberRange(0, 60);
        }
    }
  }

  /// Get time limit in seconds for a question
  static int getTimeLimit(
    AgeGroup ageGroup,
    DifficultyLevel difficulty,
  ) {
    // Younger children get more time
    final baseTime = ageGroup == AgeGroup.young
        ? 45
        : ageGroup == AgeGroup.middle
            ? 30
            : 20;

    // Harder questions get more time
    final multiplier = difficulty == DifficultyLevel.hard
        ? 1.5
        : difficulty == DifficultyLevel.medium
            ? 1.2
            : 1.0;

    return (baseTime * multiplier).round();
  }

  /// Get number of questions per session
  static int getQuestionsPerSession(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.young:
        return 8; // Shorter sessions for younger children
      case AgeGroup.middle:
        return 10;
      case AgeGroup.older:
        return 12;
    }
  }
}

enum GradeBenchmarkLevel {
  under,
  inline,
  over,
}

class GradeBenchmark {
  const GradeBenchmark({
    required this.expectedStep,
    required this.actualStep,
    required this.delta,
    required this.level,
  });

  final int expectedStep;
  final int actualStep;
  final int delta;
  final GradeBenchmarkLevel level;
}

/// Represents a range of numbers for question generation
class NumberRange {
  const NumberRange(this.min, this.max);

  final int min;
  final int max;

  bool contains(int value) => value >= min && value <= max;
}
