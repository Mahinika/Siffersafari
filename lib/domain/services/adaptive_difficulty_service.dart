import '../constants/learning_constants.dart';
import '../enums/difficulty_level.dart';

/// Adjusts question difficulty based on user performance.
///
/// Uses thresholds defined in [LearningConstants] to decide when to
/// increase, decrease, or maintain difficulty level. Requires a minimum
/// number of recent results (in [LearningConstants.questionsBeforeAdjustment])
/// before making adjustment decisions.
class AdaptiveDifficultyService {
  /// Calculates the success rate from a list of recent quiz results.
  ///
  /// Returns 0.0 if the list is empty, otherwise the ratio of correct
  /// answers to total attempts.
  double calculateSuccessRate(List<bool> recentResults) {
    if (recentResults.isEmpty) return 0.0;
    final correctCount = recentResults.where((r) => r).length;
    return correctCount / recentResults.length;
  }

  /// Suggests a new difficulty step (1–10 scale) based on performance.
  ///
  /// Applies thresholds from [LearningConstants]:
  /// - If success rate ≥ [difficultyIncreaseThreshold], increments step
  /// - If success rate ≤ [difficultyDecreaseThreshold], decrements step
  /// - Otherwise, keeps current step
  ///
  /// Returns a value clamped between [minStep] and [maxStep].
  /// Requires at least [questionsBeforeAdjustment] recent results before
  /// suggesting an increase.
  int suggestDifficultyStep({
    required int currentStep,
    required List<bool> recentResults,
    required int minStep,
    required int maxStep,
  }) {
    if (recentResults.length < LearningConstants.questionsBeforeAdjustment) {
      return currentStep.clamp(minStep, maxStep);
    }

    final successRate = calculateSuccessRate(recentResults);

    if (successRate >= LearningConstants.difficultyIncreaseThreshold) {
      return (currentStep + 1).clamp(minStep, maxStep);
    }

    if (successRate <= LearningConstants.difficultyDecreaseThreshold) {
      return (currentStep - 1).clamp(minStep, maxStep);
    }

    return currentStep.clamp(minStep, maxStep);
  }

  /// Suggests a new [DifficultyLevel] (easy/medium/hard) based on performance.
  ///
  /// Requires at least [questionsBeforeAdjustment] recent results before
  /// making a suggestion. Otherwise returns the current difficulty unchanged.
  DifficultyLevel suggestDifficulty({
    required DifficultyLevel currentDifficulty,
    required List<bool> recentResults,
  }) {
    if (recentResults.length < LearningConstants.questionsBeforeAdjustment) {
      return currentDifficulty;
    }

    final successRate = calculateSuccessRate(recentResults);

    if (successRate >= LearningConstants.difficultyIncreaseThreshold) {
      return _increaseDifficulty(currentDifficulty);
    }

    if (successRate <= LearningConstants.difficultyDecreaseThreshold) {
      return _decreaseDifficulty(currentDifficulty);
    }

    return currentDifficulty;
  }

  DifficultyLevel _increaseDifficulty(DifficultyLevel current) {
    switch (current) {
      case DifficultyLevel.easy:
        return DifficultyLevel.medium;
      case DifficultyLevel.medium:
        return DifficultyLevel.hard;
      case DifficultyLevel.hard:
        return DifficultyLevel.hard;
    }
  }

  DifficultyLevel _decreaseDifficulty(DifficultyLevel current) {
    switch (current) {
      case DifficultyLevel.easy:
        return DifficultyLevel.easy;
      case DifficultyLevel.medium:
        return DifficultyLevel.easy;
      case DifficultyLevel.hard:
        return DifficultyLevel.medium;
    }
  }
}
