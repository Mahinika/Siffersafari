import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/utils/daily_goal_utils.dart';

void main() {
  group('[Unit] DailyGoal utils', () {
    test('dailyGoalTargetKey bygger nyckel med userId', () {
      expect(dailyGoalTargetKey('user-123'), 'daily_goal_target_user-123');
    });

    test('dailyGoalProgressKey använder YYYY-MM-DD och userId', () {
      final key = dailyGoalProgressKey('u1', DateTime(2026, 3, 9));
      expect(key, 'daily_goal_progress_u1_2026-03-09');
    });
  });
}
