import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/user_progress.dart';
import '../constants/app_constants.dart';

class AchievementReward {
  const AchievementReward({
    required this.unlockedIds,
    required this.bonusPoints,
  });

  final List<String> unlockedIds;
  final int bonusPoints;

  bool get hasRewards => unlockedIds.isNotEmpty || bonusPoints > 0;
}

/// Service for checking and awarding achievements
class AchievementService {
  AchievementReward evaluate({
    required UserProgress user,
    required QuizSession session,
  }) {
    final unlocked = <String>[];
    var bonusPoints = 0;

    if (_shouldUnlockFirstQuiz(user)) {
      unlocked.add(AppConstants.firstQuizAchievement);
      bonusPoints += 50;
    }

    if (_shouldUnlockPerfectScore(session, user)) {
      unlocked.add(AppConstants.perfectScoreAchievement);
      bonusPoints += 75;
    }

    if (_shouldUnlockMaster100(user, session)) {
      unlocked.add(AppConstants.master100Achievement);
      bonusPoints += 100;
    }

    if (_shouldUnlockStreak(user, 7)) {
      unlocked.add(AppConstants.streak7Achievement);
      bonusPoints += 75;
    }

    if (_shouldUnlockStreak(user, 30)) {
      unlocked.add(AppConstants.streak30Achievement);
      bonusPoints += 150;
    }

    return AchievementReward(
      unlockedIds: unlocked,
      bonusPoints: bonusPoints,
    );
  }

  String getDisplayName(String achievementId) {
    switch (achievementId) {
      case AppConstants.firstQuizAchievement:
        return 'Första quizet';
      case AppConstants.perfectScoreAchievement:
        return 'Perfekt resultat';
      case AppConstants.master100Achievement:
        return 'Mästare 100';
      case AppConstants.streak7Achievement:
        return '7-dagars streak';
      case AppConstants.streak30Achievement:
        return '30-dagars streak';
      default:
        return 'Okänd prestation';
    }
  }

  bool _shouldUnlockFirstQuiz(UserProgress user) {
    return user.totalQuizzesTaken == 0 &&
        !user.achievements.contains(AppConstants.firstQuizAchievement);
  }

  bool _shouldUnlockPerfectScore(QuizSession session, UserProgress user) {
    return session.successRate == 1.0 &&
        !user.achievements.contains(AppConstants.perfectScoreAchievement);
  }

  bool _shouldUnlockMaster100(UserProgress user, QuizSession session) {
    final totalCorrect = user.totalCorrectAnswers + session.correctAnswers;
    return totalCorrect >= 100 &&
        !user.achievements.contains(AppConstants.master100Achievement);
  }

  bool _shouldUnlockStreak(UserProgress user, int streak) {
    return user.currentStreak >= streak &&
        !user.achievements.contains(
          streak == 7
              ? AppConstants.streak7Achievement
              : AppConstants.streak30Achievement,
        );
  }
}
