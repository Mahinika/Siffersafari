import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/adaptive_difficulty_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/question_generator_service.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';

class QuizState {
  const QuizState({
    this.session,
    this.isLoading = false,
    this.errorMessage,
    this.feedback,
    this.nextSuggestedDifficulty,
    this.recentResults = const [],
  });

  final QuizSession? session;
  final bool isLoading;
  final String? errorMessage;
  final FeedbackResult? feedback;
  final DifficultyLevel? nextSuggestedDifficulty;
  final List<bool> recentResults;

  QuizState copyWith({
    QuizSession? session,
    bool? isLoading,
    String? errorMessage,
    FeedbackResult? feedback,
    DifficultyLevel? nextSuggestedDifficulty,
    List<bool>? recentResults,
  }) {
    return QuizState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      feedback: feedback,
      nextSuggestedDifficulty:
          nextSuggestedDifficulty ?? this.nextSuggestedDifficulty,
      recentResults: recentResults ?? this.recentResults,
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
    required OperationType operationType,
    required DifficultyLevel difficulty,
  }) {
    final count = DifficultyConfig.getQuestionsPerSession(ageGroup);

    final questions = _questionGenerator.generateQuestions(
      ageGroup: ageGroup,
      operationType: operationType,
      difficulty: difficulty,
      count: count,
    );

    final session = QuizSession(
      sessionId: _uuid.v4(),
      operationType: operationType,
      difficulty: difficulty,
      questions: questions,
      startTime: DateTime.now(),
    );

    state = state.copyWith(
      session: session,
      recentResults: const [],
      feedback: null,
      nextSuggestedDifficulty: null,
    );
  }

  void startCustomSession({
    required OperationType operationType,
    required DifficultyLevel difficulty,
    required List<Question> questions,
  }) {
    if (questions.isEmpty) return;

    final session = QuizSession(
      sessionId: _uuid.v4(),
      operationType: operationType,
      difficulty: difficulty,
      questions: questions,
      startTime: DateTime.now(),
    );

    state = state.copyWith(
      session: session,
      recentResults: const [],
      feedback: null,
      nextSuggestedDifficulty: null,
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

    final updatedResults = List<bool>.from(state.recentResults)..add(isCorrect);

    const maxRecent = AppConstants.questionsBeforeAdjustment;
    if (updatedResults.length > maxRecent) {
      updatedResults.removeAt(0);
    }

    final suggestedDifficulty = _adaptiveDifficultyService.suggestDifficulty(
      currentDifficulty: session.difficulty,
      recentResults: updatedResults,
    );

    final feedback = _feedbackService.buildFeedback(
      question: question,
      userAnswer: answer,
      ageGroup: ageGroup,
    );

    state = state.copyWith(
      session: updatedSession,
      recentResults: updatedResults,
      feedback: feedback,
      nextSuggestedDifficulty: suggestedDifficulty,
    );
  }

  void goToNextQuestion() {
    final session = state.session;
    if (session == null) return;

    final nextIndex = session.currentQuestionIndex + 1;
    final isComplete = nextIndex >= session.questions.length;

    final updatedSession = session.copyWith(
      currentQuestionIndex: nextIndex,
      endTime: isComplete ? DateTime.now() : session.endTime,
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
