import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import '../../domain/services/feedback_service.dart';
import '../services/audio_service.dart';
import '../services/question_generator_service.dart';
import 'audio_service_provider.dart';
import 'feedback_service_provider.dart';
import 'local_storage_repository_provider.dart';
import 'question_generator_service_provider.dart';

class QuizState {
  const QuizState({
    this.userId,
    this.session,
    this.isLoading = false,
    this.errorMessage,
    this.feedback,
    this.difficultyStepsByOperation = const {},
    this.recentResultsByOperation = const {},
    this.correctStreak = 0,
    this.bestCorrectStreak = 0,
    this.speedBonusCount = 0,
  });

  final String? userId;
  final QuizSession? session;
  final bool isLoading;
  final String? errorMessage;
  final FeedbackResult? feedback;
  final Map<OperationType, int> difficultyStepsByOperation;
  final Map<OperationType, List<bool>> recentResultsByOperation;
  final int correctStreak;
  final int bestCorrectStreak;
  final int speedBonusCount;

  QuizState copyWith({
    String? userId,
    QuizSession? session,
    bool? isLoading,
    String? errorMessage,
    FeedbackResult? feedback,
    Map<OperationType, int>? difficultyStepsByOperation,
    Map<OperationType, List<bool>>? recentResultsByOperation,
    int? correctStreak,
    int? bestCorrectStreak,
    int? speedBonusCount,
  }) {
    return QuizState(
      userId: userId ?? this.userId,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      feedback: feedback,
      difficultyStepsByOperation:
          difficultyStepsByOperation ?? this.difficultyStepsByOperation,
      recentResultsByOperation:
          recentResultsByOperation ?? this.recentResultsByOperation,
      correctStreak: correctStreak ?? this.correctStreak,
      bestCorrectStreak: bestCorrectStreak ?? this.bestCorrectStreak,
      speedBonusCount: speedBonusCount ?? this.speedBonusCount,
    );
  }
}

/// Manages quiz session state: questions, answers, feedback, and streaks.
///
/// Key responsibilities:
/// - Generate questions for a session based on operation type and difficulty.
/// - Track user answers and calculate success rate.
/// - Evaluate feedback (correct/incorrect) and bonus points.
/// - Update streak counters and persist session progress.
/// - Support custom question lists for focus mode.
///
/// Use [startSession] to begin a quiz; [submitAnswer] to record responses.
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(
    this._questionGenerator,
    this._feedbackService,
    this._audioService,
    this._repository,
  ) : super(const QuizState());

  final QuestionGeneratorService _questionGenerator;
  final FeedbackService _feedbackService;
  final AudioService _audioService;
  final LocalStorageRepository _repository;
  final _uuid = const Uuid();

  void _persistInProgressSession({
    required String userId,
    required QuizSession session,
  }) {
    debugPrint(
      '[QuizNotifier] _persistInProgressSession: '
      'userId=$userId, operationType=${session.operationType.name}',
    );
    final answered = session.correctAnswers + session.wrongAnswers;
    if (answered <= 0) {
      debugPrint(
          '[QuizNotifier] _persistInProgressSession: no answers yet, skipping',);
      return;
    }

    final inProgressId = _repository.inProgressQuizSessionId(
      userId: userId,
      operationTypeName: session.operationType.name,
    );

    // Clean up any legacy in-progress entries so benchmark underlag doesn't
    // overcount abandoned sessions.
    unawaited(
      _repository.purgeInProgressQuizSessions(
        userId: userId,
        operationTypeName: session.operationType.name,
        exceptSessionId: inProgressId,
      ),
    );

    final now = DateTime.now();
    final start = session.startTime ?? now;
    final end = session.endTime ?? now;

    final rate = answered == 0 ? 0.0 : (session.correctAnswers / answered);

    // Fire-and-forget so answering stays snappy.
    unawaited(
      _repository.saveQuizSession({
        'sessionId': inProgressId,
        'userId': userId,
        'operationType': session.operationType.name,
        'difficulty': session.difficulty.name,
        'correctAnswers': session.correctAnswers,
        // For in-progress sessions, totalQuestions means answered so far.
        'totalQuestions': answered,
        'successRate': rate,
        'points': session.totalPoints,
        'bonusPoints': 0,
        'pointsWithBonus': session.totalPoints,
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'isComplete': false,
      }),
    );
  }

  void startSession({
    required String userId,
    required AgeGroup ageGroup,
    int? gradeLevel,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    Map<OperationType, int>? initialDifficultyStepsByOperation,
    bool? wordProblemsEnabled,
    bool? missingNumberEnabled,
  }) {
    debugPrint(
      '[QuizNotifier] startSession: userId=$userId, '
      'operation=${operationType.name}, difficulty=${difficulty.name}',
    );
    final inProgressId = _repository.inProgressQuizSessionId(
      userId: userId,
      operationTypeName: operationType.name,
    );

    // Reset in-progress underlag immediately when the child starts playing the
    // same operation again (even before the first answer).
    unawaited(
      _repository.saveQuizSession({
        'sessionId': inProgressId,
        'userId': userId,
        'operationType': operationType.name,
        'difficulty': difficulty.name,
        'correctAnswers': 0,
        'totalQuestions': 0,
        'successRate': 0.0,
        'points': 0,
        'bonusPoints': 0,
        'pointsWithBonus': 0,
        'startTime': DateTime.now().toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'isComplete': false,
      }),
    );

    // Also purge any legacy in-progress entries for the same operation.
    unawaited(
      _repository.purgeInProgressQuizSessions(
        userId: userId,
        operationTypeName: operationType.name,
        exceptSessionId: inProgressId,
      ),
    );

    final count = DifficultyConfig.getQuestionsPerSession(ageGroup);

    final steps = Map<OperationType, int>.unmodifiable(
      initialDifficultyStepsByOperation ??
          DifficultyConfig.buildDifficultySteps(
            storedSteps: const {},
            defaultDifficulty: difficulty,
            gradeLevel: gradeLevel,
          ),
    );

    final effectiveWordProblemsEnabled = wordProblemsEnabled ?? true;
    final effectiveMissingNumberEnabled = missingNumberEnabled ?? true;

    final firstQuestion = _questionGenerator.generateQuestion(
      ageGroup: ageGroup,
      operationType: operationType,
      difficulty: difficulty,
      difficultyStepsByOperation: steps,
      gradeLevel: gradeLevel,
      wordProblemsEnabledOverride: effectiveWordProblemsEnabled,
      missingNumberEnabledOverride: effectiveMissingNumberEnabled,
    );

    final session = QuizSession(
      sessionId: _uuid.v4(),
      ageGroup: ageGroup,
      gradeLevel: gradeLevel,
      operationType: operationType,
      difficulty: difficulty,
      questions: [firstQuestion],
      targetQuestionCount: count,
      wordProblemsEnabled: effectiveWordProblemsEnabled,
      missingNumberEnabled: effectiveMissingNumberEnabled,
      difficultyStepsByOperation: steps,
      startTime: DateTime.now(),
    );

    state = state.copyWith(
      userId: userId,
      session: session,
      feedback: null,
      difficultyStepsByOperation: steps,
      recentResultsByOperation: const {},
      correctStreak: 0,
      bestCorrectStreak: 0,
      speedBonusCount: 0,
    );
  }

  void startCustomSession({
    required String userId,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    required List<Question> questions,
    required AgeGroup ageGroup,
    int? gradeLevel,
    Map<OperationType, int>? initialDifficultyStepsByOperation,
    bool? wordProblemsEnabled,
    bool? missingNumberEnabled,
  }) {
    debugPrint(
      '[QuizNotifier] startCustomSession: userId=$userId, '
      'operation=${operationType.name}, questions=${questions.length}',
    );
    if (questions.isEmpty) {
      debugPrint(
          '[QuizNotifier] startCustomSession: empty questions list, skipping',);
      return;
    }

    final inProgressId = _repository.inProgressQuizSessionId(
      userId: userId,
      operationTypeName: operationType.name,
    );

    unawaited(
      _repository.saveQuizSession({
        'sessionId': inProgressId,
        'userId': userId,
        'operationType': operationType.name,
        'difficulty': difficulty.name,
        'correctAnswers': 0,
        'totalQuestions': 0,
        'successRate': 0.0,
        'points': 0,
        'bonusPoints': 0,
        'pointsWithBonus': 0,
        'startTime': DateTime.now().toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'isComplete': false,
      }),
    );

    unawaited(
      _repository.purgeInProgressQuizSessions(
        userId: userId,
        operationTypeName: operationType.name,
        exceptSessionId: inProgressId,
      ),
    );

    final effectiveWordProblemsEnabled = wordProblemsEnabled ?? true;
    final effectiveMissingNumberEnabled = missingNumberEnabled ?? true;

    final steps = Map<OperationType, int>.unmodifiable(
      initialDifficultyStepsByOperation ??
          DifficultyConfig.buildDifficultySteps(
            storedSteps: const {},
            defaultDifficulty: difficulty,
            gradeLevel: gradeLevel,
          ),
    );

    final session = QuizSession(
      sessionId: _uuid.v4(),
      ageGroup: ageGroup,
      gradeLevel: gradeLevel,
      operationType: operationType,
      difficulty: difficulty,
      questions: questions,
      targetQuestionCount: questions.length,
      wordProblemsEnabled: effectiveWordProblemsEnabled,
      missingNumberEnabled: effectiveMissingNumberEnabled,
      difficultyStepsByOperation: steps,
      startTime: DateTime.now(),
    );

    state = state.copyWith(
      userId: userId,
      session: session,
      feedback: null,
      difficultyStepsByOperation: steps,
      recentResultsByOperation: const {},
      correctStreak: 0,
      bestCorrectStreak: 0,
      speedBonusCount: 0,
    );
  }

  void submitAnswer({
    required int answer,
    required Duration responseTime,
    required AgeGroup ageGroup,
  }) {
    final session = state.session;
    if (session == null || session.currentQuestion == null) {
      debugPrint('[QuizNotifier] submitAnswer: no active session');
      return;
    }

    final question = session.currentQuestion!;
    final isCorrect = question.isCorrect(answer);
    debugPrint(
      '[QuizNotifier] submitAnswer: question=${question.id}, '
      'answer=$answer, correct=$isCorrect, time=${responseTime.inSeconds}s',
    );

    if (isCorrect) {
      _audioService.playCorrectSound();
    } else {
      _audioService.playWrongSound();
    }

    final updatedAnswers = Map<String, int>.from(session.answers)
      ..[question.id] = answer;

    final updatedTimes = Map<String, Duration>.from(session.responseTimes)
      ..[question.id] = responseTime;

    final pointsEarned = _calculatePoints(
      isCorrect: isCorrect,
      responseTime: responseTime,
      difficulty: session.difficulty,
    );

    final gotSpeedBonus = isCorrect && responseTime.inSeconds <= 5;
    final previousStreak = state.correctStreak;
    final newStreak = isCorrect ? (state.correctStreak + 1) : 0;
    final newBestStreak = newStreak > state.bestCorrectStreak
        ? newStreak
        : state.bestCorrectStreak;
    final newSpeedBonusCount = state.speedBonusCount + (gotSpeedBonus ? 1 : 0);

    final isLastQuestion =
        session.currentQuestionIndex >= session.questions.length - 1;

    final updatedSession = session.copyWith(
      correctAnswers: session.correctAnswers + (isCorrect ? 1 : 0),
      wrongAnswers: session.wrongAnswers + (isCorrect ? 0 : 1),
      totalPoints: session.totalPoints + pointsEarned,
      answers: updatedAnswers,
      responseTimes: updatedTimes,
      endTime: isLastQuestion ? DateTime.now() : session.endTime,
    );

    final op = question.operationType;

    final updatedResultsByOperation =
        Map<OperationType, List<bool>>.from(state.recentResultsByOperation);
    final updatedOpResults =
        List<bool>.from(updatedResultsByOperation[op] ?? const [])
          ..add(isCorrect);
    const maxRecent = AppConstants.questionsBeforeAdjustment;
    if (updatedOpResults.length > maxRecent) {
      updatedOpResults.removeAt(0);
    }
    updatedResultsByOperation[op] = updatedOpResults;

    final feedback = _feedbackService.buildFeedback(
      question: question,
      userAnswer: answer,
      ageGroup: ageGroup,
      pointsEarned: pointsEarned,
      gotSpeedBonus: gotSpeedBonus,
      correctStreak: isCorrect ? newStreak : previousStreak,
    );

    state = state.copyWith(
      session: updatedSession,
      feedback: feedback,
      recentResultsByOperation: Map<OperationType, List<bool>>.unmodifiable(
        updatedResultsByOperation.map(
          (k, v) => MapEntry(k, List<bool>.unmodifiable(v)),
        ),
      ),
      correctStreak: newStreak,
      bestCorrectStreak: newBestStreak,
      speedBonusCount: newSpeedBonusCount,
    );

    final userId = state.userId;
    if (userId != null && userId.isNotEmpty) {
      debugPrint(
          '[QuizNotifier] submitAnswer: persisting session for userId=$userId',);
      _persistInProgressSession(userId: userId, session: updatedSession);
    }
  }

  void goToNextQuestion() {
    final session = state.session;
    if (session == null) return;

    final nextIndex = session.currentQuestionIndex + 1;
    final isComplete = nextIndex >= session.totalQuestions;

    var updatedQuestions = session.questions;
    if (!isComplete && nextIndex >= updatedQuestions.length) {
      final nextQuestion = _questionGenerator.generateQuestion(
        ageGroup: session.ageGroup,
        operationType: session.operationType,
        difficulty: session.difficulty,
        difficultyStepsByOperation: state.difficultyStepsByOperation,
        gradeLevel: session.gradeLevel,
        wordProblemsEnabledOverride: session.wordProblemsEnabled,
        missingNumberEnabledOverride: session.missingNumberEnabled,
      );
      updatedQuestions = [...updatedQuestions, nextQuestion];
    }

    final updatedSession = session.copyWith(
      currentQuestionIndex: nextIndex,
      endTime: isComplete ? DateTime.now() : session.endTime,
      questions: updatedQuestions,
    );

    state = state.copyWith(
      session: updatedSession,
      feedback: null,
    );
  }

  void clearFeedback() {
    if (state.feedback == null) return;
    state = state.copyWith(feedback: null);
  }

  int _calculatePoints({
    required bool isCorrect,
    required Duration responseTime,
    required DifficultyLevel difficulty,
  }) {
    if (!isCorrect) return 0;

    var points = AppConstants.basePointsPerQuestion;
    points = (points * difficulty.pointMultiplier).round();

    if (responseTime.inSeconds <= 5) {
      points += AppConstants.bonusPointsForSpeed;
    }

    return points;
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final generator = ref.watch(questionGeneratorServiceProvider);
  final feedback = ref.watch(feedbackServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  final repo = ref.watch(localStorageRepositoryProvider);

  return QuizNotifier(generator, feedback, audio, repo);
});
