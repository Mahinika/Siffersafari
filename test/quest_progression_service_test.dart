import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/services/quest_progression_service.dart';
import 'package:math_game_app/domain/entities/user_progress.dart';
import 'package:math_game_app/domain/enums/age_group.dart';

void main() {
  group('QuestProgressionService', () {
    const service = QuestProgressionService();

    test('defaults to first quest when no quest state', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );

      final status = service.getCurrentStatus(
        user: user,
        currentQuestId: null,
        completedQuestIds: <String>{},
      );

      expect(status.quest.id, 'q_plus_easy');
      expect(status.progress, 0.0);
      expect(status.isCompleted, isFalse);
    });

    test('for Åk 1-2 path includes only easy quests', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
        gradeLevel: 1,
      );

      final firstId = service.firstQuestId(user);
      expect(firstId, 'q_plus_easy');

      // Jump to last easy quest and ensure next is null (no medium in path).
      final nextAfterDivEasy = service.nextQuestId(
        user: user,
        currentQuestId: 'q_div_easy',
      );
      expect(nextAfterDivEasy, isNull);
    });

    test('when currentQuestId is outside path, selects first available in path',
        () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
        gradeLevel: 1,
      );

      final status = service.getCurrentStatus(
        user: user,
        currentQuestId: 'q_plus_medium',
        completedQuestIds: <String>{},
      );

      expect(status.quest.id, 'q_plus_easy');
    });

    test('marks quest completed when mastery reaches threshold', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
        masteryLevels: {
          'addition_easy': 0.81,
        },
      );

      final status = service.getCurrentStatus(
        user: user,
        currentQuestId: 'q_plus_easy',
        completedQuestIds: <String>{},
      );

      expect(status.quest.id, 'q_plus_easy');
      expect(status.isCompleted, isTrue);
      expect(status.progress, 1.0);
    });

    test('skips completed quests and selects next one', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );

      final status = service.getCurrentStatus(
        user: user,
        currentQuestId: 'q_plus_easy',
        completedQuestIds: <String>{'q_plus_easy'},
      );

      expect(status.quest.id, 'q_minus_easy');
    });
  });
}
