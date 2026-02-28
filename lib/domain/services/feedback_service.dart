import '../entities/question.dart';
import '../enums/age_group.dart';

class FeedbackResult {
  const FeedbackResult({
    required this.isCorrect,
    required this.title,
    required this.message,
  });

  final bool isCorrect;
  final String title;
  final String message;
}

/// Service for generating feedback messages
class FeedbackService {
  FeedbackResult buildFeedback({
    required Question question,
    required int userAnswer,
    required AgeGroup ageGroup,
  }) {
    final isCorrect = question.isCorrect(userAnswer);

    if (isCorrect) {
      return FeedbackResult(
        isCorrect: true,
        title: _getPositiveTitle(ageGroup),
        message: question.explanation ?? 'Ratt! Bra jobbat.',
      );
    }

    return FeedbackResult(
      isCorrect: false,
      title: _getEncouragingTitle(ageGroup),
      message: _buildIncorrectMessage(question, userAnswer),
    );
  }

  String _getPositiveTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.young:
        return 'Super!';
      case AgeGroup.middle:
        return 'Bra jobbat!';
      case AgeGroup.older:
        return 'Snyggt!';
    }
  }

  String _getEncouragingTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.young:
        return 'Forsok igen!';
      case AgeGroup.middle:
        return 'Nastan!';
      case AgeGroup.older:
        return 'Lite fel, men du klarar det!';
    }
  }

  String _buildIncorrectMessage(Question question, int userAnswer) {
    final correct = question.correctAnswer;
    final explanation = question.explanation ?? question.questionText;

    return 'Du svarade $userAnswer. Ratt svar ar $correct. $explanation.';
  }
}
