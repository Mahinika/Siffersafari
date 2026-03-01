import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('DifficultyConfig.effectiveAllowedOperations', () {
    test('utan Åk: returnerar exakt parent set', () {
      final parent = <OperationType>{
        OperationType.division,
      };

      final effective = DifficultyConfig.effectiveAllowedOperations(
        parentAllowedOperations: parent,
        gradeLevel: null,
      );

      expect(effective, parent);
    });

    test('om Åk-filter ger tomt: faller tillbaka till parent set', () {
      // Åk 1–2 visar normalt bara +/−, men om föräldern har valt bara ÷
      // så ska ÷ ändå visas (föräldern har sista ordet).
      final parent = <OperationType>{
        OperationType.division,
      };

      final effective = DifficultyConfig.effectiveAllowedOperations(
        parentAllowedOperations: parent,
        gradeLevel: 1,
      );

      expect(effective, parent);
      expect(effective.contains(OperationType.division), isTrue);
    });
  });

  group('DifficultyConfig grade benchmark', () {
    test('expectedDifficultyStepForGrade är konservativ i låg Åk', () {
      expect(
        DifficultyConfig.expectedDifficultyStepForGrade(
          gradeLevel: 1,
          operation: OperationType.addition,
        ),
        2,
      );
      expect(
        DifficultyConfig.expectedDifficultyStepForGrade(
          gradeLevel: 1,
          operation: OperationType.division,
        ),
        1,
      );
    });

    test('compareDifficultyStepToGrade klassar under/i linje/över', () {
      // Åk 4: plus expected 5.
      final expected = DifficultyConfig.expectedDifficultyStepForGrade(
        gradeLevel: 4,
        operation: OperationType.addition,
      );
      expect(expected, 5);

      final under = DifficultyConfig.compareDifficultyStepToGrade(
        gradeLevel: 4,
        operation: OperationType.addition,
        difficultyStep: expected - 3,
      );
      expect(under.level, GradeBenchmarkLevel.under);

      final inline = DifficultyConfig.compareDifficultyStepToGrade(
        gradeLevel: 4,
        operation: OperationType.addition,
        difficultyStep: expected + 1,
      );
      expect(inline.level, GradeBenchmarkLevel.inline);

      // Med tolerans ±2 ska även +2 vara i linje.
      final inline2 = DifficultyConfig.compareDifficultyStepToGrade(
        gradeLevel: 4,
        operation: OperationType.addition,
        difficultyStep: expected + 2,
      );
      expect(inline2.level, GradeBenchmarkLevel.inline);

      final over = DifficultyConfig.compareDifficultyStepToGrade(
        gradeLevel: 4,
        operation: OperationType.addition,
        difficultyStep: expected + 3,
      );
      expect(over.level, GradeBenchmarkLevel.over);
    });
  });

  group('DifficultyConfig.parentSuggestedAdjustmentSteps', () {
    test('returnerar större steg när man rör sig mot indikatorn', () {
      // Under (delta=-6): om föräldern trycker "Svårare" -> större steg.
      const under = GradeBenchmark(
        expectedStep: 6,
        actualStep: 0,
        delta: -6,
        level: GradeBenchmarkLevel.under,
      );
      expect(
        DifficultyConfig.parentSuggestedAdjustmentSteps(
          benchmark: under,
          makeHarder: true,
        ),
        3,
      );

      // Over (delta=+4): om föräldern trycker "Lättare" -> större steg.
      const over = GradeBenchmark(
        expectedStep: 4,
        actualStep: 8,
        delta: 4,
        level: GradeBenchmarkLevel.over,
      );
      expect(
        DifficultyConfig.parentSuggestedAdjustmentSteps(
          benchmark: over,
          makeHarder: false,
        ),
        2,
      );
    });

    test('är försiktig (1 steg) om föräldern går emot indikatorn', () {
      const under = GradeBenchmark(
        expectedStep: 5,
        actualStep: 2,
        delta: -3,
        level: GradeBenchmarkLevel.under,
      );
      expect(
        DifficultyConfig.parentSuggestedAdjustmentSteps(
          benchmark: under,
          makeHarder: false,
        ),
        1,
      );
    });
  });

  group('DifficultyConfig.recommendedDifficultyStepForTraining', () {
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
          averageSuccessRate: 0.90,
        ),
        6,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.96,
        ),
        7,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.80,
        ),
        4,
      );
      expect(
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: 0.60,
        ),
        3,
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

  group('DifficultyConfig.effectiveAgeGroup', () {
    test('använder fallback när gradeLevel saknas', () {
      expect(
        DifficultyConfig.effectiveAgeGroup(
          fallback: AgeGroup.middle,
          gradeLevel: null,
        ),
        AgeGroup.middle,
      );
    });

    test('mappar Åk 1–3 till young', () {
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

    test('mappar Åk 4–6 till middle', () {
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

    test('mappar Åk 7–9 till older', () {
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
    test('använder fallback när gradeLevel saknas', () {
      expect(
        DifficultyConfig.effectiveDifficulty(
          fallback: DifficultyLevel.medium,
          gradeLevel: null,
        ),
        DifficultyLevel.medium,
      );
    });

    test('mappar årskurser till repeterande easy/medium/hard-buckets', () {
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
    test('young har längst grundtid', () {
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

    test('hard ger mer tid än easy', () {
      final easy =
          DifficultyConfig.getTimeLimit(AgeGroup.middle, DifficultyLevel.easy);
      final hard =
          DifficultyConfig.getTimeLimit(AgeGroup.middle, DifficultyLevel.hard);
      expect(hard, greaterThan(easy));
    });
  });

  group('DifficultyConfig.getQuestionsPerSession', () {
    test('returnerar förväntat antal frågor', () {
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.young), 8);
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.middle), 10);
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.older), 12);
    });
  });

  group('DifficultyConfig.getNumberRange', () {
    test('intervallet innehåller sina ändpunkter', () {
      final range = DifficultyConfig.getNumberRange(
        AgeGroup.young,
        OperationType.addition,
        DifficultyLevel.easy,
      );

      expect(range.contains(range.min), isTrue);
      expect(range.contains(range.max), isTrue);
    });

    test('olika åldersgrupper ger olika max för addition/easy', () {
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
