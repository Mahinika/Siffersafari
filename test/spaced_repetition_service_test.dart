import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/domain/services/spaced_repetition_service.dart';

void main() {
  group('SpacedRepetitionService', () {
    late SpacedRepetitionService service;

    setUp(() {
      service = SpacedRepetitionService();
    });

    test('första rätta svar schemaläggs till 2 dagar', () {
      final now = DateTime(2026, 3, 4);

      final schedule = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        previous: null,
        now: now,
      );

      expect(schedule.intervalDays, 2);
      expect(schedule.consecutiveCorrect, 1);
      expect(schedule.nextReviewDate, now.add(const Duration(days: 2)));
    });

    test('fel svar reset: interval tillbaka till 2 dagar och streak 0', () {
      final now = DateTime(2026, 3, 4);
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

      expect(schedule.intervalDays, 2);
      expect(schedule.consecutiveCorrect, 0);
      expect(schedule.nextReviewDate, now.add(const Duration(days: 2)));
    });

    test('korrekta svar eskalerar 2 -> 7 -> 14 dagar', () {
      final now = DateTime(2026, 3, 4);

      final s1 = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        now: now,
      );
      expect(s1.intervalDays, 2);

      final s2 = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        previous: s1,
        now: now,
      );
      expect(s2.intervalDays, 7);

      final s3 = service.scheduleNextReview(
        questionId: 'q1',
        wasCorrect: true,
        previous: s2,
        now: now,
      );
      expect(s3.intervalDays, 14);
    });

    test('getDueQuestionIds returnerar endast frågor som är due', () {
      final now = DateTime(2026, 3, 4, 12);
      final schedules = <ReviewSchedule>[
        ReviewSchedule(
          questionId: 'due1',
          nextReviewDate: now,
          intervalDays: 2,
          consecutiveCorrect: 1,
        ),
        ReviewSchedule(
          questionId: 'due2',
          nextReviewDate: now.subtract(const Duration(minutes: 1)),
          intervalDays: 2,
          consecutiveCorrect: 1,
        ),
        ReviewSchedule(
          questionId: 'later',
          nextReviewDate: now.add(const Duration(minutes: 1)),
          intervalDays: 2,
          consecutiveCorrect: 1,
        ),
      ];

      final due = service.getDueQuestionIds(schedules, now);
      expect(due, containsAll(<String>['due1', 'due2']));
      expect(due, isNot(contains('later')));
    });
  });
}
