import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/constants/app_constants.dart';
import 'package:math_game_app/core/services/spaced_repetition_service.dart';

void main() {
  group('SpacedRepetitionService', () {
    late SpacedRepetitionService service;

    setUp(() {
      service = SpacedRepetitionService();
    });

    test('schedules first review with correct interval', () {
      final now = DateTime(2026, 1, 1);
      final schedule = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        now: now,
      );

      expect(schedule.consecutiveCorrect, 1);
      expect(schedule.intervalDays, AppConstants.firstReviewInterval);
      expect(
        schedule.nextReviewDate,
        now.add(const Duration(days: AppConstants.firstReviewInterval)),
      );
    });

    test('resets interval on incorrect answer', () {
      final now = DateTime(2026, 1, 1);
      final previous = ReviewSchedule(
        questionId: 'q1',
        nextReviewDate: now,
        intervalDays: 7,
        consecutiveCorrect: 2,
      );

      final schedule = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: false,
        previous: previous,
        now: now,
      );

      expect(schedule.consecutiveCorrect, 0);
      expect(schedule.intervalDays, AppConstants.firstReviewInterval);
    });

    test('increases interval after consecutive correct answers', () {
      final now = DateTime(2026, 1, 1);
      var schedule = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        now: now,
      );

      expect(schedule.intervalDays, AppConstants.firstReviewInterval);

      schedule = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        previous: schedule,
        now: now,
      );

      expect(schedule.intervalDays, AppConstants.secondReviewInterval);

      schedule = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        previous: schedule,
        now: now,
      );

      expect(schedule.intervalDays, AppConstants.thirdReviewInterval);
    });

    test('identifies due questions correctly', () {
      final now = DateTime(2026, 1, 10);

      final schedules = [
        ReviewSchedule(
          questionId: 'q1',
          nextReviewDate: DateTime(2026, 1, 9), // Due
          intervalDays: 2,
          consecutiveCorrect: 1,
        ),
        ReviewSchedule(
          questionId: 'q2',
          nextReviewDate: DateTime(2026, 1, 11), // Not due
          intervalDays: 2,
          consecutiveCorrect: 1,
        ),
        ReviewSchedule(
          questionId: 'q3',
          nextReviewDate: DateTime(2026, 1, 10), // Due today
          intervalDays: 2,
          consecutiveCorrect: 1,
        ),
      ];

      final dueIds = service.getDueQuestionIds(schedules, now);

      expect(dueIds, containsAll(['q1', 'q3']));
      expect(dueIds, isNot(contains('q2')));
    });
  });
}
