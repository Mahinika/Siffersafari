String dailyGoalTargetKey(String userId) => 'daily_goal_target_$userId';

String dailyGoalProgressKey(String userId, DateTime date) {
  return 'daily_goal_progress_${userId}_${_dateKey(date)}';
}

String _dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

const int defaultDailyGoalTarget = 10;
