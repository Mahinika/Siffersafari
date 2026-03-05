import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/providers/quiz_provider.dart';
import 'package:math_game_app/core/services/audio_service.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/data/repositories/local_storage_repository.dart';
import 'package:math_game_app/domain/entities/question.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';
import 'package:math_game_app/domain/services/feedback_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioService extends Mock implements AudioService {}

class _InMemoryLocalStorageRepository extends LocalStorageRepository {
  final Map<String, Map<String, dynamic>> quizHistory = {};

  @override
  Future<void> saveQuizSession(Map<String, dynamic> session) async {
    final sessionId = session['sessionId'] as String;
    quizHistory[sessionId] = session;
  }

  @override
  Future<void> purgeInProgressQuizSessions({
    required String userId,
    required String operationTypeName,
    String? exceptSessionId,
  }) async {
    final keys = quizHistory.keys.toList(growable: false);
    for (final key in keys) {
      final session = quizHistory[key];
      if (session == null) continue;

      if (exceptSessionId != null && session['sessionId'] == exceptSessionId) {
        continue;
      }

      if (session['userId'] != userId) continue;
      if (session['operationType'] != operationTypeName) continue;
      if (session['isComplete'] != false) continue;

      quizHistory.remove(key);
    }
  }
}

class _FakeQuestionGeneratorService extends QuestionGeneratorService {
  static const Question question = Question(
    id: 'q1',
    operationType: OperationType.multiplication,
    difficulty: DifficultyLevel.easy,
    operand1: 6,
    operand2: 7,
    correctAnswer: 42,
    wrongAnswers: [41, 43, 40],
    explanation: '6 × 7 = 42',
  );

  @override
  Question generateQuestion({
    required AgeGroup ageGroup,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    Map<OperationType, int>? difficultyStepsByOperation,
    int? difficultyStep,
    int? gradeLevel,
    bool? wordProblemsEnabledOverride,
    double? wordProblemsChanceOverride,
    bool? missingNumberEnabledOverride,
    double? missingNumberChanceOverride,
  }) {
    return question;
  }
}

void main() {
  group('Quiz progression edge cases', () {
    test(
        'Unit (QuizNotifier): startSession resets in-progress underlag and purges legacy entries',
        () async {
      final repo = _InMemoryLocalStorageRepository();
      final audio = _MockAudioService();
      when(() => audio.playCorrectSound()).thenAnswer((_) async {});
      when(() => audio.playWrongSound()).thenAnswer((_) async {});

      // Seed a legacy in-progress session that should be purged.
      repo.quizHistory['legacy_inprogress'] = {
        'sessionId': 'legacy_inprogress',
        'userId': 'u1',
        'operationType': OperationType.multiplication.name,
        'difficulty': DifficultyLevel.easy.name,
        'correctAnswers': 1,
        'totalQuestions': 1,
        'successRate': 1.0,
        'points': 10,
        'bonusPoints': 0,
        'pointsWithBonus': 10,
        'startTime': DateTime(2026, 1, 1).toIso8601String(),
        'endTime': DateTime(2026, 1, 1).toIso8601String(),
        'isComplete': false,
      };

      final notifier = QuizNotifier(
        _FakeQuestionGeneratorService(),
        FeedbackService(),
        audio,
        repo,
      );

      notifier.startSession(
        userId: 'u1',
        ageGroup: AgeGroup.middle,
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
      );

      // Flush fire-and-forget writes.
      await pumpEventQueue();

      final inProgressId = repo.inProgressQuizSessionId(
        userId: 'u1',
        operationTypeName: OperationType.multiplication.name,
      );

      expect(repo.quizHistory.containsKey('legacy_inprogress'), isFalse);
      expect(repo.quizHistory.containsKey(inProgressId), isTrue);
      expect(repo.quizHistory[inProgressId]!['totalQuestions'], 0);
      expect(repo.quizHistory[inProgressId]!['correctAnswers'], 0);

      // First answer should overwrite the same in-progress session with answered so far.
      notifier.submitAnswer(
        answer: _FakeQuestionGeneratorService.question.correctAnswer,
        responseTime: const Duration(seconds: 3),
        ageGroup: AgeGroup.middle,
      );

      await pumpEventQueue();

      expect(repo.quizHistory[inProgressId]!['totalQuestions'], 1);
      expect(repo.quizHistory[inProgressId]!['correctAnswers'], 1);
      expect(repo.quizHistory[inProgressId]!['isComplete'], isFalse);
      expect(repo.quizHistory[inProgressId]!['successRate'], 1.0);
    });

    test(
        'Unit (QuizNotifier): startCustomSession with empty questions is a no-op',
        () async {
      final repo = _InMemoryLocalStorageRepository();
      final audio = _MockAudioService();
      when(() => audio.playCorrectSound()).thenAnswer((_) async {});
      when(() => audio.playWrongSound()).thenAnswer((_) async {});

      final notifier = QuizNotifier(
        _FakeQuestionGeneratorService(),
        FeedbackService(),
        audio,
        repo,
      );

      notifier.startCustomSession(
        userId: 'u1',
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
        questions: const [],
        ageGroup: AgeGroup.middle,
      );

      await pumpEventQueue();

      expect(notifier.state.session, isNull);
      expect(repo.quizHistory, isEmpty);
    });
  });
}
