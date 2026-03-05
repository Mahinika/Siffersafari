import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';

void main() {
  group('[Unit] DifficultyConfig – Training difficulty recommendation', () {
    test('returnerar null om data saknas', () {
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: null,
        ),
        isNull,
      );
    });

    test('håller steget nära 85% och justerar i små steg', () {
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.85,
        ),
        5,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.86,
        ),
        6,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.90,
        ),
        6,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.96,
        ),
        6,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.80,
        ),
        5,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.60,
        ),
        4,
      );
    });

    test('clamp: går aldrig under 1 eller över 10', () {
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 10,
          averageSuccessRate: 0.99,
        ),
        10,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 1,
          averageSuccessRate: 0.0,
        ),
        1,
      );
    });
  });

  group('[Unit] DifficultyConfig – Age group helpers', () {
    test('effectiveAgeGroup använder fallback när gradeLevel saknas', () {
      expect(
        DifficultyConfig.effectiveAgeGroup(
          fallback: AgeGroup.middle,
          gradeLevel: null,
        ),
        AgeGroup.middle,
      );
    });

    test('effectiveAgeGroup mappar Åk 1–3 till young', () {
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

    test('effectiveAgeGroup mappar Åk 4–6 till middle', () {
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

    test('effectiveAgeGroup mappar Åk 7–9 till older', () {
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

  group('[Unit] DifficultyConfig – Difficulty level helpers', () {
    test('effectiveDifficulty använder fallback när gradeLevel saknas', () {
      expect(
        DifficultyConfig.effectiveDifficulty(
          fallback: DifficultyLevel.medium,
          gradeLevel: null,
        ),
        DifficultyLevel.medium,
      );
    });

    test(
        'effectiveDifficulty mappar årskurser till repeterande easy/medium/hard-buckets',
        () {
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
}
