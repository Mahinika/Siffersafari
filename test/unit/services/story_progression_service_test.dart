import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/services/quest_progression_service.dart';
import 'package:siffersafari/core/services/story_progression_service.dart';
import 'package:siffersafari/domain/entities/user_progress.dart';
import 'package:siffersafari/domain/enums/age_group.dart';

void main() {
  group('[Unit] StoryProgressionService', () {
    const questService = QuestProgressionService();
    const storyService = StoryProgressionService();

    test('bygger jungle-progress från första questen', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );

      final questStatus = questService.getCurrentStatus(
        user: user,
        currentQuestId: null,
        completedQuestIds: <String>{},
      );

      final story = storyService.build(
        path: questService.questsForUser(user),
        currentStatus: questStatus,
        completedQuestIds: const <String>{},
      );

      expect(story.worldTitle, 'Ville i djungeln');
      expect(story.totalNodes, 20);
      expect(story.currentNodeIndex, 0);
      expect(story.completedNodes, 0);
      expect(story.nodes.first.state.name, 'current');
      expect(story.nodes.first.landmark, 'Startlägret');
      expect(
        story.nodes.first.landmarkHint,
        'Ett tryggt basläger vid djungelns kant.',
      );
      expect(story.nodes.first.sceneTag, 'baslager');
      expect(story.chapterTitle, 'Kapitel 1: Den första stigen');
    });

    test('markerar tidigare noder som completed', () {
      const user = UserProgress(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );

      final questStatus = questService.getCurrentStatus(
        user: user,
        currentQuestId: 'q_times_easy',
        completedQuestIds: <String>{'q_plus_easy', 'q_minus_easy'},
      );

      final story = storyService.build(
        path: questService.questsForUser(user),
        currentStatus: questStatus,
        completedQuestIds: const <String>{'q_plus_easy', 'q_minus_easy'},
      );

      expect(story.completedNodes, 2);
      expect(story.currentNode?.id, 'q_times_easy');
      expect(story.nodes[0].state.name, 'completed');
      expect(story.nodes[1].state.name, 'completed');
      expect(story.nodes[2].state.name, 'current');
    });
  });
}
