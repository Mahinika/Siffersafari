/// Pure, domain-level constants for learning rules/algorithms.
///
/// Keep this file Flutter-free so domain services stay platform-agnostic.
class LearningConstants {
  LearningConstants._();

  // Spaced Repetition Intervals (in days)
  static const int firstReviewInterval = 2;
  static const int secondReviewInterval = 7;
  static const int thirdReviewInterval = 14;

  // Adaptive Difficulty
  static const int questionsBeforeAdjustment = 5;
  static const double difficultyIncreaseThreshold = 0.85;
  static const double difficultyDecreaseThreshold = 0.60;
}
