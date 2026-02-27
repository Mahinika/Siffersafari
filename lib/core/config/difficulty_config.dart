import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';

/// Configuration for difficulty levels based on age groups
class DifficultyConfig {
  DifficultyConfig._();

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

/// Represents a range of numbers for question generation
class NumberRange {
  const NumberRange(this.min, this.max);

  final int min;
  final int max;

  bool contains(int value) => value >= min && value <= max;
}
