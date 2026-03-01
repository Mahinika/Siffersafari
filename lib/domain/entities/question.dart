import 'package:equatable/equatable.dart';

import '../enums/difficulty_level.dart';
import '../enums/operation_type.dart';

/// Represents a single math question
class Question extends Equatable {
  const Question({
    required this.id,
    required this.operationType,
    required this.difficulty,
    required this.operand1,
    required this.operand2,
    required this.correctAnswer,
    this.promptText,
    this.wrongAnswers = const [],
    this.explanation,
  });

  final String id;
  final OperationType operationType;
  final DifficultyLevel difficulty;
  final int operand1;
  final int operand2;
  final int correctAnswer;
  final String? promptText;
  final List<int> wrongAnswers;
  final String? explanation;

  /// Format the question as a string (e.g., "5 + 3")
  String get questionText {
    return promptText ?? '$operand1 ${operationType.symbol} $operand2';
  }

  /// Get all answer options (correct + wrong answers)
  List<int> get allAnswerOptions {
    final options = [correctAnswer, ...wrongAnswers];
    options.shuffle();
    return options;
  }

  /// Check if an answer is correct
  bool isCorrect(int answer) => answer == correctAnswer;

  Question copyWith({
    String? id,
    OperationType? operationType,
    DifficultyLevel? difficulty,
    int? operand1,
    int? operand2,
    int? correctAnswer,
    String? promptText,
    List<int>? wrongAnswers,
    String? explanation,
  }) {
    return Question(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      difficulty: difficulty ?? this.difficulty,
      operand1: operand1 ?? this.operand1,
      operand2: operand2 ?? this.operand2,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      promptText: promptText ?? this.promptText,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        operationType,
        difficulty,
        operand1,
        operand2,
        correctAnswer,
      promptText,
        wrongAnswers,
        explanation,
      ];
}
