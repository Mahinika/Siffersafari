import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_features.dart';
import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/settings_keys.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/constants/learning_constants.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import '../../domain/services/adaptive_difficulty_service.dart';
import '../../domain/services/feedback_service.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../services/audio_service.dart';
import '../services/question_generator_service.dart';
import 'audio_service_provider.dart';
import 'feedback_service_provider.dart';
import 'local_storage_repository_provider.dart';
import 'question_generator_service_provider.dart';
import 'spaced_repetition_service_provider.dart';

// region QuizState Class

class QuizState {
  const QuizState({
    this.userId,
    this.session,
    this.isLoading = false,
    this.errorMessage,
    this.feedback,
    this.difficultyStepsByOperation = const {},
    this.recentResultsByOperation = const {},
    this.questionsSinceLastStepChangeByOperation = const {},
    this.correctStreak = 0,
    this.bestCorrectStreak = 0,
    this.speedBonusCount = 0,
    this.reviewSchedulesByKey = const {},
    this.dueReviewCount = 0,
  });

  final String? userId;
  final QuizSession? session;
  final bool isLoading;
  final String? errorMessage;
  final FeedbackResult? feedback;
  final Map<OperationType, int> difficultyStepsByOperation;
  final Map<OperationType, List<bool>> recentResultsByOperation;
  final Map<OperationType, int> questionsSinceLastStepChangeByOperation;
  final int correctStreak;
  final int bestCorrectStreak;
  final int speedBonusCount;
  final Map<String, ReviewSchedule> reviewSchedulesByKey;
  final int dueReviewCount;

  QuizState copyWith({
    String? userId,
    QuizSession? session,
    bool? isLoading,
    String? errorMessage,
    FeedbackResult? feedback,
    Map<OperationType, int>? difficultyStepsByOperation,
    Map<OperationType, List<bool>>? recentResultsByOperation,
    Map<OperationType, int>? questionsSinceLastStepChangeByOperation,
    int? correctStreak,
    int? bestCorrectStreak,
    int? speedBonusCount,
    Map<String, ReviewSchedule>? reviewSchedulesByKey,
    int? dueReviewCount,
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
      questionsSinceLastStepChangeByOperation:
          questionsSinceLastStepChangeByOperation ??
              this.questionsSinceLastStepChangeByOperation,
      correctStreak: correctStreak ?? this.correctStreak,
      bestCorrectStreak: bestCorrectStreak ?? this.bestCorrectStreak,
      speedBonusCount: speedBonusCount ?? this.speedBonusCount,
      reviewSchedulesByKey: reviewSchedulesByKey ?? this.reviewSchedulesByKey,
      dueReviewCount: dueReviewCount ?? this.dueReviewCount,
    );
  }
}

// endregion

// region QuizNotifier Class

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
    this._repository, {
    AdaptiveDifficultyService? adaptiveDifficultyService,
    SpacedRepetitionService? spacedRepetitionService,
  })  : _adaptiveDifficultyService =
            adaptiveDifficultyService ?? AdaptiveDifficultyService(),
        _spacedRepetitionService =
            spacedRepetitionService ?? SpacedRepetitionService(),
        super(const QuizState());

  final QuestionGeneratorService _questionGenerator;
  final FeedbackService _feedbackService;
  final AudioService _audioService;
  final LocalStorageRepository _repository;
  final AdaptiveDifficultyService _adaptiveDifficultyService;
  final SpacedRepetitionService _spacedRepetitionService;
  final _uuid = const Uuid();

  String _reviewKeyForQuestion(Question question) {
    // Question IDs are per-session UUIDs, so use a stable content key instead.
    return '${question.operationType.name}|${question.displayQuestionText}';
  }

  Map<String, ReviewSchedule> _loadReviewSchedules(String userId) {
    dynamic raw;
    try {
      raw = _repository.getSetting(
        SettingsKeys.spacedRepetitionSchedules(userId),
      );
    } catch (e) {
      debugPrint(
        '[QuizNotifier] _loadReviewSchedules skipped (storage unavailable): $e',
      );
      return const <String, ReviewSchedule>{};
    }
    if (raw is! List) return const <String, ReviewSchedule>{};

    final map = <String, ReviewSchedule>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final entry = Map<String, dynamic>.from(item);
      final key = entry['key']?.toString();
      final questionId = entry['questionId']?.toString();
      final nextReviewRaw = entry['nextReviewDate']?.toString();
      final intervalDays = entry['intervalDays'];
      final consecutiveCorrect = entry['consecutiveCorrect'];

      if (key == null || key.isEmpty) continue;
      if (questionId == null || questionId.isEmpty) continue;
      final nextReviewDate = DateTime.tryParse(nextReviewRaw ?? '');
      if (nextReviewDate == null) continue;
      if (intervalDays is! int || consecutiveCorrect is! int) continue;

      map[key] = ReviewSchedule(
        questionId: questionId,
        nextReviewDate: nextReviewDate,
        intervalDays: intervalDays,
        consecutiveCorrect: consecutiveCorrect,
      );
    }

    return map;
  }

  Future<void> _saveReviewSchedules(
    String userId,
    Map<String, ReviewSchedule> schedules,
  ) async {
    final raw = schedules.entries
        .map(
          (entry) => {
            'key': entry.key,
            'questionId': entry.value.questionId,
            'nextReviewDate': entry.value.nextReviewDate.toIso8601String(),
            'intervalDays': entry.value.intervalDays,
            'consecutiveCorrect': entry.value.consecutiveCorrect,
          },
        )
        .toList(growable: false);

    try {
      await _repository.saveSetting(
        SettingsKeys.spacedRepetitionSchedules(userId),
        raw,
      );
    } catch (e) {
      debugPrint(
        '[QuizNotifier] _saveReviewSchedules skipped (storage unavailable): $e',
      );
    }
  }

  int _countDueReviews(Map<String, ReviewSchedule> schedules, DateTime now) {
    return _spacedRepetitionService
        .getDueQuestionIds(schedules.values.toList(growable: false), now)
        .length;
  }

  bool _isSpacedRepetitionEnabled(String userId) {
    try {
      final raw = _repository.getSetting(
        SettingsKeys.spacedRepetitionEnabled(userId),
        defaultValue: AppFeatures.spacedRepetitionEnabled,
      );
      return raw is bool ? raw : AppFeatures.spacedRepetitionEnabled;
    } catch (_) {
      return AppFeatures.spacedRepetitionEnabled;
    }
  }

  void hydrateReviewSummaryForUser(String userId) {
    if (userId.isEmpty) return;

    final isEnabled = _isSpacedRepetitionEnabled(userId);
    final reviewSchedules =
        isEnabled ? _loadReviewSchedules(userId) : const <String, ReviewSchedule>{};
    final dueCount =
        isEnabled ? _countDueReviews(reviewSchedules, DateTime.now()) : 0;

    state = state.copyWith(
      userId: userId,
      reviewSchedulesByKey: Map<String, ReviewSchedule>.unmodifiable(
        reviewSchedules,
      ),
      dueReviewCount: dueCount,
    );
  }

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
        '[QuizNotifier] _persistInProgressSession: no answers yet, skipping',
      );
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

    final isSpacedRepetitionEnabled = _isSpacedRepetitionEnabled(userId);
    final reviewSchedules = isSpacedRepetitionEnabled
      ? _loadReviewSchedules(userId)
      : const <String, ReviewSchedule>{};
    final dueCount = isSpacedRepetitionEnabled
      ? _countDueReviews(reviewSchedules, DateTime.now())
      : 0;

    state = state.copyWith(
      userId: userId,
      session: session,
      feedback: null,
      difficultyStepsByOperation: steps,
      recentResultsByOperation: const {},
      questionsSinceLastStepChangeByOperation: const {},
      correctStreak: 0,
      bestCorrectStreak: 0,
      speedBonusCount: 0,
      reviewSchedulesByKey: Map<String, ReviewSchedule>.unmodifiable(
        reviewSchedules,
      ),
      dueReviewCount: dueCount,
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
        '[QuizNotifier] startCustomSession: empty questions list, skipping',
      );
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

    final isSpacedRepetitionEnabled = _isSpacedRepetitionEnabled(userId);
    final reviewSchedules = isSpacedRepetitionEnabled
      ? _loadReviewSchedules(userId)
      : const <String, ReviewSchedule>{};
    final dueCount = isSpacedRepetitionEnabled
      ? _countDueReviews(reviewSchedules, DateTime.now())
      : 0;

    state = state.copyWith(
      userId: userId,
      session: session,
      feedback: null,
      difficultyStepsByOperation: steps,
      recentResultsByOperation: const {},
      questionsSinceLastStepChangeByOperation: const {},
      correctStreak: 0,
      bestCorrectStreak: 0,
      speedBonusCount: 0,
      reviewSchedulesByKey: Map<String, ReviewSchedule>.unmodifiable(
        reviewSchedules,
      ),
      dueReviewCount: dueCount,
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

    final currentStep = DifficultyConfig.clampDifficultyStep(
      state.difficultyStepsByOperation[op] ??
          DifficultyConfig.minDifficultyStep,
    );
    final questionsSinceLastStepChange =
        state.questionsSinceLastStepChangeByOperation[op] ??
            LearningConstants.cooldownQuestionsAfterStepChange;

    final suggestedStep = _adaptiveDifficultyService.suggestDifficultyStep(
      currentStep: currentStep,
      recentResults: updatedOpResults,
      minStep: DifficultyConfig.minDifficultyStep,
      maxStep: DifficultyConfig.maxDifficultyStep,
      questionsSinceLastStepChange: questionsSinceLastStepChange,
    );

    final updatedDifficultySteps =
        Map<OperationType, int>.from(state.difficultyStepsByOperation)
          ..[op] = suggestedStep;

    final updatedQuestionsSinceLastStepChangeByOperation =
        Map<OperationType, int>.from(
      state.questionsSinceLastStepChangeByOperation,
    )..[op] =
            suggestedStep != currentStep ? 0 : questionsSinceLastStepChange + 1;

    final feedback = _feedbackService.buildFeedback(
      question: question,
      userAnswer: answer,
      ageGroup: ageGroup,
      pointsEarned: pointsEarned,
      gotSpeedBonus: gotSpeedBonus,
      correctStreak: isCorrect ? newStreak : previousStreak,
    );

    final userId = state.userId;
    final isSpacedRepetitionEnabled =
        userId != null && userId.isNotEmpty && _isSpacedRepetitionEnabled(userId);

    final updatedReviewSchedules = isSpacedRepetitionEnabled
        ? (() {
            final reviewKey = _reviewKeyForQuestion(question);
            final previousReview = state.reviewSchedulesByKey[reviewKey];
            final updatedReview = _spacedRepetitionService.scheduleNextReview(
              questionId: reviewKey,
              wasCorrect: isCorrect,
              previous: previousReview,
              now: DateTime.now(),
            );
            return Map<String, ReviewSchedule>.from(state.reviewSchedulesByKey)
              ..[reviewKey] = updatedReview;
          })()
        : const <String, ReviewSchedule>{};
    final dueCount = isSpacedRepetitionEnabled
        ? _countDueReviews(updatedReviewSchedules, DateTime.now())
        : 0;

    state = state.copyWith(
      session: updatedSession.copyWith(
        difficultyStepsByOperation: Map<OperationType, int>.unmodifiable(
          updatedDifficultySteps,
        ),
      ),
      feedback: feedback,
      difficultyStepsByOperation: Map<OperationType, int>.unmodifiable(
        updatedDifficultySteps,
      ),
      recentResultsByOperation: Map<OperationType, List<bool>>.unmodifiable(
        updatedResultsByOperation.map(
          (k, v) => MapEntry(k, List<bool>.unmodifiable(v)),
        ),
      ),
      questionsSinceLastStepChangeByOperation:
          Map<OperationType, int>.unmodifiable(
        updatedQuestionsSinceLastStepChangeByOperation,
      ),
      correctStreak: newStreak,
      bestCorrectStreak: newBestStreak,
      speedBonusCount: newSpeedBonusCount,
      reviewSchedulesByKey: Map<String, ReviewSchedule>.unmodifiable(
        updatedReviewSchedules,
      ),
      dueReviewCount: dueCount,
    );

    if (userId != null && userId.isNotEmpty) {
      debugPrint(
        '[QuizNotifier] submitAnswer: persisting session for userId=$userId',
      );
      _persistInProgressSession(userId: userId, session: updatedSession);
      if (isSpacedRepetitionEnabled) {
        unawaited(_saveReviewSchedules(userId, updatedReviewSchedules));
      }
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

// endregion

// region Provider Definition

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final generator = ref.watch(questionGeneratorServiceProvider);
  final feedback = ref.watch(feedbackServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  final repo = ref.watch(localStorageRepositoryProvider);
  final spacedRepetition = ref.watch(spacedRepetitionServiceProvider);

  return QuizNotifier(
    generator,
    feedback,
    audio,
    repo,
    spacedRepetitionService: spacedRepetition,
  );
});

// endregion
