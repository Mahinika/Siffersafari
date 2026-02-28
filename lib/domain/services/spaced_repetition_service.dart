import '../constants/learning_constants.dart';

/// Represents a scheduled review for a question
class ReviewSchedule {
  const ReviewSchedule({
    required this.questionId,
    required this.nextReviewDate,
    required this.intervalDays,
    required this.consecutiveCorrect,
  });

  final String questionId;
  final DateTime nextReviewDate;
  final int intervalDays;
  final int consecutiveCorrect;

  ReviewSchedule copyWith({
    String? questionId,
    DateTime? nextReviewDate,
    int? intervalDays,
    int? consecutiveCorrect,
  }) {
    return ReviewSchedule(
      questionId: questionId ?? this.questionId,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      intervalDays: intervalDays ?? this.intervalDays,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
    );
  }
}

/// Service for spaced repetition scheduling
class SpacedRepetitionService {
  /// Schedule the next review based on the result
  ReviewSchedule scheduleNextReview({
    required String questionId,
    required bool wasCorrect,
    ReviewSchedule? previous,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (previous == null) {
      const intervalDays = LearningConstants.firstReviewInterval;
      return ReviewSchedule(
        questionId: questionId,
        nextReviewDate: currentTime.add(const Duration(days: intervalDays)),
        intervalDays: intervalDays,
        consecutiveCorrect: wasCorrect ? 1 : 0,
      );
    }

    if (!wasCorrect) {
      const intervalDays = LearningConstants.firstReviewInterval;
      return previous.copyWith(
        nextReviewDate: currentTime.add(const Duration(days: intervalDays)),
        intervalDays: intervalDays,
        consecutiveCorrect: 0,
      );
    }

    final newConsecutiveCorrect = previous.consecutiveCorrect + 1;
    final intervalDays = _getNextInterval(newConsecutiveCorrect);

    return previous.copyWith(
      nextReviewDate: currentTime.add(Duration(days: intervalDays)),
      intervalDays: intervalDays,
      consecutiveCorrect: newConsecutiveCorrect,
    );
  }

  /// Returns the next interval based on consecutive correct answers
  int _getNextInterval(int consecutiveCorrect) {
    if (consecutiveCorrect >= 3) return LearningConstants.thirdReviewInterval;
    if (consecutiveCorrect == 2) return LearningConstants.secondReviewInterval;
    return LearningConstants.firstReviewInterval;
  }

  /// Get question IDs that are due for review
  List<String> getDueQuestionIds(
    List<ReviewSchedule> schedules,
    DateTime now,
  ) {
    return schedules
        .where((schedule) => !schedule.nextReviewDate.isAfter(now))
        .map((schedule) => schedule.questionId)
        .toList();
  }
}
