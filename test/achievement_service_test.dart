import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/services/achievement_service.dart';
import 'package:math_game_app/domain/entities/quiz_session.dart';
import 'package:math_game_app/domain/entities/user_progress.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('AchievementService', () {
    late AchievementService service;

    setUp(() {
      service = AchievementService();
    });

    test('Unit (AchievementService): låser upp första quiz-utmärkelsen', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );

      const session = QuizSession(
        sessionId: 's1',
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        questions: [],
        correctAnswers: 0,
        wrongAnswers: 0,
        totalPoints: 0,
      );

      final reward = service.evaluate(user: user, session: session);
      expect(reward.unlockedIds.isNotEmpty, true);
    });
  });
}
