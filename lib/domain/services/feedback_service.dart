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
    int? pointsEarned,
    bool? gotSpeedBonus,
    int? correctStreak,
  }) {
    final isCorrect = question.isCorrect(userAnswer);
    final correct = question.correctAnswer;
    final hint = question.explanation?.trim();

    final safePointsEarned = pointsEarned ?? 0;
    final safeGotSpeedBonus = gotSpeedBonus ?? false;
    final safeCorrectStreak = correctStreak ?? 0;

    if (isCorrect) {
      final message = (hint != null && hint.isNotEmpty)
          ? '✨ $hint'
          : '✨ ${question.questionText} = $correct';

      final metaLines = _buildMetaLines(
        pointsEarned: safePointsEarned,
        gotSpeedBonus: safeGotSpeedBonus,
        correctStreak: safeCorrectStreak,
        wasCorrect: true,
      );

      return FeedbackResult(
        isCorrect: true,
        title: _getPositiveTitle(
          ageGroup,
          seed: question.id,
          gotSpeedBonus: safeGotSpeedBonus,
          correctStreak: safeCorrectStreak,
        ),
        message: _joinLines([message, ...metaLines]),
      );
    }

    final incorrectMessage = _buildIncorrectMessage(
      question: question,
      userAnswer: userAnswer,
      hint: hint,
    );

    final metaLines = _buildMetaLines(
      pointsEarned: safePointsEarned,
      gotSpeedBonus: safeGotSpeedBonus,
      correctStreak: safeCorrectStreak,
      wasCorrect: false,
    );

    return FeedbackResult(
      isCorrect: false,
      title: _getEncouragingTitle(ageGroup, seed: question.id),
      message: _joinLines([incorrectMessage, ...metaLines]),
    );
  }

  String _getPositiveTitle(
    AgeGroup ageGroup, {
    required String seed,
    required bool gotSpeedBonus,
    required int correctStreak,
  }) {
    if (gotSpeedBonus) {
      final options = switch (ageGroup) {
        AgeGroup.young => const ['Blixtsnabb!', 'Supersnabb!', 'ZOOOM!'],
        AgeGroup.middle => const ['Blixtsnabb!', 'Snabbbonus!', 'Raketfart!'],
        AgeGroup.older => const [
            'Snabbt jobbat!',
            'Blixtsnabbt!',
            'Raketfart!',
          ],
      };
      return _pick(seed, options);
    }

    if (correctStreak >= 3) {
      final options = switch (ageGroup) {
        AgeGroup.young => const ['Svit-super!', 'Du är i zonen!', 'Eldsvit!'],
        AgeGroup.middle => const [
            'Svit-mästare!',
            'Du är i zonen!',
            'Eldsvit!',
          ],
        AgeGroup.older => const [
            'Stabil svit!',
            'Du är i zonen!',
            'Snygg svit!',
          ],
      };
      return _pick(seed, options);
    }

    final options = switch (ageGroup) {
      AgeGroup.young => const ['WOW!', 'Woho!', 'Snyggt!', 'Kanon!'],
      AgeGroup.middle => const [
          'Grymt jobbat!',
          'Snyggt!',
          'Kanon!',
          'Starkt!',
        ],
      AgeGroup.older => const [
          'Klockrent!',
          'Stabilt!',
          'Snyggt!',
          'Bra jobbat!',
        ],
    };
    return _pick(seed, options);
  }

  String _getEncouragingTitle(AgeGroup ageGroup, {required String seed}) {
    final options = switch (ageGroup) {
      AgeGroup.young => const ['Hoppsan! Testa igen!', 'Nära!', 'Okej — igen!'],
      AgeGroup.middle => const ['Nästan!', 'Nära!', 'Bra försök!'],
      AgeGroup.older => const [
          'Lite fel — du fixar det!',
          'Nära!',
          'Bra försök!',
        ],
    };
    return _pick(seed, options);
  }

  String _buildIncorrectMessage({
    required Question question,
    required int userAnswer,
    required String? hint,
  }) {
    final correct = question.correctAnswer;
    final hintLine = (hint != null && hint.isNotEmpty)
        ? '💡 $hint'
        : '💡 ${question.questionText} = $correct';

    return 'Du valde $userAnswer\nRätt är $correct\n$hintLine';
  }

  List<String> _buildMetaLines({
    required int pointsEarned,
    required bool gotSpeedBonus,
    required int correctStreak,
    required bool wasCorrect,
  }) {
    final lines = <String>[];

    if (pointsEarned > 0) {
      lines.add('🪙 +$pointsEarned poäng');
    }

    if (gotSpeedBonus) {
      lines.add('⚡ Snabbbonus!');
    }

    if (wasCorrect) {
      if (correctStreak >= 2) {
        lines.add('🔥 Sviten: $correctStreak');
      }
    } else {
      if (correctStreak >= 2) {
        lines.add('🔥 Svit (nyss): $correctStreak');
      }
    }

    return lines;
  }

  String _pick(String seed, List<String> options) {
    if (options.isEmpty) return '';
    final index = _stableHash(seed) % options.length;
    return options[index];
  }

  int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _joinLines(List<String> parts) {
    final cleaned = parts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return cleaned.join('\n');
  }
}
