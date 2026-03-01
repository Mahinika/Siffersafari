import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/question_generator_service.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import '../../domain/services/adaptive_difficulty_service.dart';
import '../../domain/services/feedback_service.dart';

class QuizState {
  const QuizState({
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

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(
    this._questionGenerator,
    this._adaptiveDifficultyService,
    this._feedbackService,
    this._audioService,
  ) : super(const QuizState());

  final QuestionGeneratorService _questionGenerator;
  final AdaptiveDifficultyService _adaptiveDifficultyService;
  final FeedbackService _feedbackService;
  final AudioService _audioService;
  final _uuid = const Uuid();

  void startSession({
    required AgeGroup ageGroup,
    int? gradeLevel,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    Map<OperationType, int>? initialDifficultyStepsByOperation,
  }) {
    final count = DifficultyConfig.getQuestionsPerSession(ageGroup);

    final steps = Map<OperationType, int>.unmodifiable(
      initialDifficultyStepsByOperation ??
          DifficultyConfig.buildDifficultySteps(
            storedSteps: const {},
            defaultDifficulty: difficulty,
          ),
    );

    final firstQuestion = _questionGenerator.generateQuestion(
      ageGroup: ageGroup,
      operationType: operationType,
      difficulty: difficulty,
      difficultyStepsByOperation: steps,
      gradeLevel: gradeLevel,
    );

    final session = QuizSession(
      sessionId: _uuid.v4(),
      ageGroup: ageGroup,
      gradeLevel: gradeLevel,
      operationType: operationType,
      difficulty: difficulty,
      questions: [firstQuestion],
      targetQuestionCount: count,
      difficultyStepsByOperation: steps,
      startTime: DateTime.now(),
    );

    state = state.copyWith(
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
    required OperationType operationType,
    required DifficultyLevel difficulty,
    required List<Question> questions,
    required AgeGroup ageGroup,
    int? gradeLevel,
    Map<OperationType, int>? initialDifficultyStepsByOperation,
  }) {
    if (questions.isEmpty) return;

    final steps = Map<OperationType, int>.unmodifiable(
      initialDifficultyStepsByOperation ??
          DifficultyConfig.buildDifficultySteps(
            storedSteps: const {},
            defaultDifficulty: difficulty,
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
      difficultyStepsByOperation: steps,
      startTime: DateTime.now(),
    );

    state = state.copyWith(
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
    if (session == null || session.currentQuestion == null) return;

    final question = session.currentQuestion!;
    final isCorrect = question.isCorrect(answer);

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

    final updatedSteps =
        Map<OperationType, int>.from(state.difficultyStepsByOperation);
    final currentStep = updatedSteps[op] ??
        DifficultyConfig.initialStepForDifficulty(session.difficulty);
    final suggestedStep = _adaptiveDifficultyService.suggestDifficultyStep(
      currentStep: currentStep,
      recentResults: updatedOpResults,
      minStep: DifficultyConfig.minDifficultyStep,
      maxStep: DifficultyConfig.maxDifficultyStep,
    );
    updatedSteps[op] = suggestedStep;

    final feedback = _feedbackService.buildFeedback(
      question: question,
      userAnswer: answer,
      ageGroup: ageGroup,
      pointsEarned: pointsEarned,
      gotSpeedBonus: gotSpeedBonus,
      correctStreak: isCorrect ? newStreak : previousStreak,
    );

    final updatedSessionWithSteps = updatedSession.copyWith(
      difficultyStepsByOperation:
          Map<OperationType, int>.unmodifiable(updatedSteps),
    );

    state = state.copyWith(
      session: updatedSessionWithSteps,
      feedback: feedback,
      difficultyStepsByOperation:
          Map<OperationType, int>.unmodifiable(updatedSteps),
      recentResultsByOperation: Map<OperationType, List<bool>>.unmodifiable(
        updatedResultsByOperation.map(
          (k, v) => MapEntry(k, List<bool>.unmodifiable(v)),
        ),
      ),
      correctStreak: newStreak,
      bestCorrectStreak: newBestStreak,
      speedBonusCount: newSpeedBonusCount,
    );
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
  final generator = getIt<QuestionGeneratorService>();
  final adaptive = getIt<AdaptiveDifficultyService>();
  final feedback = getIt<FeedbackService>();
  final audio = getIt<AudioService>();

  return QuizNotifier(generator, adaptive, feedback, audio);
});
