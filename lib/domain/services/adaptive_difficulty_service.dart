import '../constants/learning_constants.dart';
import '../enums/difficulty_level.dart';

/// Service for adaptive difficulty adjustments
class AdaptiveDifficultyService {
  /// Calculate success rate from recent results
  double calculateSuccessRate(List<bool> recentResults) {
    if (recentResults.isEmpty) return 0.0;
    final correctCount = recentResults.where((r) => r).length;
    return correctCount / recentResults.length;
  }

  /// Suggest new difficulty based on recent performance
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
