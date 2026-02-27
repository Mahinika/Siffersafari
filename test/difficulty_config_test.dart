import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('DifficultyConfig.effectiveAgeGroup', () {
    test('returns fallback when gradeLevel is null', () {
      expect(
        DifficultyConfig.effectiveAgeGroup(
          fallback: AgeGroup.middle,
          gradeLevel: null,
        ),
        AgeGroup.middle,
      );
    });

    test('maps Åk 1-3 to young', () {
      for (final grade in [1, 2, 3]) {
        expect(
          DifficultyConfig.effectiveAgeGroup(
            fallback: AgeGroup.older,
            gradeLevel: grade,
          ),
          AgeGroup.young,
        );
      }
    });

    test('maps Åk 4-6 to middle', () {
      for (final grade in [4, 5, 6]) {
        expect(
          DifficultyConfig.effectiveAgeGroup(
            fallback: AgeGroup.young,
            gradeLevel: grade,
          ),
          AgeGroup.middle,
        );
      }
    });

    test('maps Åk 7-9 to older', () {
      for (final grade in [7, 8, 9]) {
        expect(
          DifficultyConfig.effectiveAgeGroup(
            fallback: AgeGroup.young,
            gradeLevel: grade,
          ),
          AgeGroup.older,
        );
      }
    });
  });

  group('DifficultyConfig.effectiveDifficulty', () {
    test('returns fallback when gradeLevel is null', () {
      expect(
        DifficultyConfig.effectiveDifficulty(
          fallback: DifficultyLevel.medium,
          gradeLevel: null,
        ),
        DifficultyLevel.medium,
      );
    });

    test('maps grades into repeating easy/medium/hard buckets', () {
      final expectations = <int, DifficultyLevel>{
        1: DifficultyLevel.easy,
        2: DifficultyLevel.medium,
        3: DifficultyLevel.hard,
        4: DifficultyLevel.easy,
        5: DifficultyLevel.medium,
        6: DifficultyLevel.hard,
        7: DifficultyLevel.easy,
        8: DifficultyLevel.medium,
        9: DifficultyLevel.hard,
      };

      expectations.forEach((grade, expected) {
        expect(
          DifficultyConfig.effectiveDifficulty(
            fallback: DifficultyLevel.easy,
            gradeLevel: grade,
          ),
          expected,
          reason: 'Åk $grade should map to $expected',
        );
      });
    });
  });

  group('DifficultyConfig.getTimeLimit', () {
    test('young has the longest base time', () {
      expect(
        DifficultyConfig.getTimeLimit(AgeGroup.young, DifficultyLevel.easy),
        greaterThan(
          DifficultyConfig.getTimeLimit(AgeGroup.middle, DifficultyLevel.easy),
        ),
      );
      expect(
        DifficultyConfig.getTimeLimit(AgeGroup.middle, DifficultyLevel.easy),
        greaterThan(
          DifficultyConfig.getTimeLimit(AgeGroup.older, DifficultyLevel.easy),
        ),
      );
    });

    test('hard difficulty gives more time than easy', () {
      final easy =
          DifficultyConfig.getTimeLimit(AgeGroup.middle, DifficultyLevel.easy);
      final hard =
          DifficultyConfig.getTimeLimit(AgeGroup.middle, DifficultyLevel.hard);
      expect(hard, greaterThan(easy));
    });
  });

  group('DifficultyConfig.getQuestionsPerSession', () {
    test('returns expected question counts', () {
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.young), 8);
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.middle), 10);
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.older), 12);
    });
  });

  group('DifficultyConfig.getNumberRange', () {
    test('range contains its endpoints', () {
      final range = DifficultyConfig.getNumberRange(
        AgeGroup.young,
        OperationType.addition,
        DifficultyLevel.easy,
      );

      expect(range.contains(range.min), isTrue);
      expect(range.contains(range.max), isTrue);
    });

    test('different age groups produce different addition-easy max', () {
      final young = DifficultyConfig.getNumberRange(
        AgeGroup.young,
        OperationType.addition,
        DifficultyLevel.easy,
      );
      final middle = DifficultyConfig.getNumberRange(
        AgeGroup.middle,
        OperationType.addition,
        DifficultyLevel.easy,
      );
      final older = DifficultyConfig.getNumberRange(
        AgeGroup.older,
        OperationType.addition,
        DifficultyLevel.easy,
      );

      expect(young.max, lessThan(middle.max));
      expect(middle.max, lessThan(older.max));
    });
  });
}
