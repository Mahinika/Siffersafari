import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/constants/app_constants.dart';
import 'package:math_game_app/core/services/achievement_service.dart';
import 'package:math_game_app/domain/entities/quiz_session.dart';
import 'package:math_game_app/domain/entities/user_progress.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('[Unit] AchievementService', () {
    late AchievementService service;

    setUp(() {
      service = AchievementService();
    });

    test('låser upp första quiz-utmärkelsen', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );

      const session = QuizSession(
        sessionId: 's1',
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        questions: [],
        targetQuestionCount: 0,
        correctAnswers: 0,
        wrongAnswers: 0,
        totalPoints: 0,
      );

      final reward = service.evaluate(user: user, session: session);
      expect(reward.unlockedIds.isNotEmpty, true);
    });

    test(
        'låser inte upp redan upplåst achievement igen',
        () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
        achievements: [AppConstants.firstQuizAchievement],
      );

      const session = QuizSession(
        sessionId: 's1',
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        questions: [],
        targetQuestionCount: 0,
        correctAnswers: 0,
        wrongAnswers: 0,
        totalPoints: 0,
      );

      final reward = service.evaluate(user: user, session: session);
      expect(
        reward.unlockedIds,
        isNot(contains(AppConstants.firstQuizAchievement)),
      );
    });

    test('streak-7 triggar men inte streak-30 vid 7', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
        currentStreak: 7,
      );

      const session = QuizSession(
        sessionId: 's1',
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        questions: [],
        targetQuestionCount: 10,
        correctAnswers: 7,
        wrongAnswers: 3,
        totalPoints: 70,
      );

      final reward = service.evaluate(user: user, session: session);
      expect(reward.unlockedIds, contains(AppConstants.streak7Achievement));
      expect(
        reward.unlockedIds,
        isNot(contains(AppConstants.streak30Achievement)),
      );
    });
  });
}
