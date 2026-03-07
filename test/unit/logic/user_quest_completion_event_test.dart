import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siffersafari/core/providers/user_provider.dart';
import 'package:siffersafari/core/services/achievement_service.dart';
import 'package:siffersafari/core/services/quest_progression_service.dart';
import 'package:siffersafari/domain/entities/question.dart';
import 'package:siffersafari/domain/entities/quiz_session.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/domain/enums/difficulty_level.dart';
import 'package:siffersafari/domain/enums/operation_type.dart';

import '../../test_utils.dart';

void main() {
  group('[Unit] UserNotifier quest completion event', () {
    late InMemoryLocalStorageRepository repository;
    late UserNotifier notifier;
    late MockAudioService audioService;

    setUp(() async {
      repository = InMemoryLocalStorageRepository();
      audioService = MockAudioService();
      when(() => audioService.setSoundEnabled(any())).thenReturn(null);
      when(() => audioService.setMusicEnabled(any())).thenReturn(null);

      notifier = UserNotifier(
        repository,
        AchievementService(),
        audioService,
        const QuestProgressionService(),
      );

      await notifier.createUser(
        userId: 'u1',
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
    });

    test('sätter quest completion event när första questen blir klar',
        () async {
      const question = Question(
        id: 'q_add',
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        operand1: 2,
        operand2: 3,
        correctAnswer: 5,
        wrongAnswers: [4, 6, 7],
        explanation: '2 + 3 = 5',
      );

      const session = QuizSession(
        sessionId: 's1',
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        questions: [question],
        targetQuestionCount: 10,
        correctAnswers: 10,
        wrongAnswers: 0,
        totalPoints: 100,
        answers: {'q_add': 5},
      );

      await notifier.applyQuizResult(session);

      expect(notifier.state.lastQuestCompletion, isNotNull);
      expect(
        notifier.state.lastQuestCompletion?.completedQuestId,
        'q_plus_easy',
      );
      expect(
        notifier.state.lastQuestCompletion?.completedQuestTitle,
        'Samla sifferfrukter',
      );
      expect(notifier.state.questStatus?.quest.id, 'q_minus_easy');
      expect(
        notifier.state.lastQuestCompletion?.nextQuestTitle,
        'Hitta borttappade siffror',
      );
    });

    test('sätter inget quest completion event när mastery inte räcker',
        () async {
      const question = Question(
        id: 'q_add_2',
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        operand1: 1,
        operand2: 1,
        correctAnswer: 2,
        wrongAnswers: [0, 3, 4],
        explanation: '1 + 1 = 2',
      );

      const session = QuizSession(
        sessionId: 's2',
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        questions: [question],
        targetQuestionCount: 10,
        correctAnswers: 7,
        wrongAnswers: 3,
        totalPoints: 70,
        answers: {'q_add_2': 2},
      );

      await notifier.applyQuizResult(session);

      expect(notifier.state.lastQuestCompletion, isNull);
      expect(notifier.state.questStatus?.quest.id, 'q_plus_easy');
    });
  });
}
