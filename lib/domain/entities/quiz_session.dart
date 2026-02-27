import 'package:equatable/equatable.dart';

import '../enums/difficulty_level.dart';
import '../enums/operation_type.dart';
import 'question.dart';

/// Represents a quiz session in progress
class QuizSession extends Equatable {
  const QuizSession({
    required this.sessionId,
    required this.operationType,
    required this.difficulty,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.totalPoints = 0,
    this.startTime,
    this.endTime,
    this.answers = const {},
    this.responseTimes = const {},
  });

  final String sessionId;
  final OperationType operationType;
  final DifficultyLevel difficulty;
  final List<Question> questions;
  final int currentQuestionIndex;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalPoints;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, int> answers; // questionId -> userAnswer
  final Map<String, Duration> responseTimes; // questionId -> time taken

  /// Get the current question
  Question? get currentQuestion {
    if (currentQuestionIndex >= questions.length) return null;
    return questions[currentQuestionIndex];
  }

  /// Check if the session is complete
  bool get isComplete => currentQuestionIndex >= questions.length;

  /// Get total questions
  int get totalQuestions => questions.length;

  /// Get success rate
  double get successRate {
    final answered = correctAnswers + wrongAnswers;
    if (answered == 0) return 0.0;
    return correctAnswers / answered;
  }

  /// Get average response time
  Duration get averageResponseTime {
    if (responseTimes.isEmpty) return Duration.zero;
    final total =
        responseTimes.values.fold(Duration.zero, (prev, curr) => prev + curr);
    return Duration(
      milliseconds: total.inMilliseconds ~/ responseTimes.length,
    );
  }

  /// Calculate session duration
  Duration? get sessionDuration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  QuizSession copyWith({
    String? sessionId,
    OperationType? operationType,
    DifficultyLevel? difficulty,
    List<Question>? questions,
    int? currentQuestionIndex,
    int? correctAnswers,
    int? wrongAnswers,
    int? totalPoints,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, int>? answers,
    Map<String, Duration>? responseTimes,
  }) {
    return QuizSession(
      sessionId: sessionId ?? this.sessionId,
      operationType: operationType ?? this.operationType,
      difficulty: difficulty ?? this.difficulty,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      totalPoints: totalPoints ?? this.totalPoints,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      answers: answers ?? this.answers,
      responseTimes: responseTimes ?? this.responseTimes,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        operationType,
        difficulty,
        questions,
        currentQuestionIndex,
        correctAnswers,
        wrongAnswers,
        totalPoints,
        startTime,
        endTime,
        answers,
        responseTimes,
      ];
}
