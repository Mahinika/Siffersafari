import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('[Unit] DifficultyConfig – Grade benchmarks', () {
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

    test(
        'testmatris: expected step ger alltid I linje (Åk 1-9, alla räknesätt)',
        () {
      final grades = List<int>.generate(9, (i) => i + 1);
      final operations = <OperationType>[
        OperationType.addition,
        OperationType.subtraction,
        OperationType.multiplication,
        OperationType.division,
      ];

      for (final grade in grades) {
        for (final operation in operations) {
          final expected = DifficultyConfig.expectedDifficultyStepForGrade(
            gradeLevel: grade,
            operation: operation,
          );
          final benchmark = DifficultyConfig.compareDifficultyStepToGrade(
            gradeLevel: grade,
            operation: operation,
            difficultyStep: expected,
          );

          expect(
            benchmark.level,
            GradeBenchmarkLevel.inline,
            reason: 'Åk $grade, $operation, step $expected should be inline',
          );
          expect(benchmark.delta, 0);
        }
      }
    });

    test('testmatris: tolerance ±2 klassas som I linje', () {
      final grades = List<int>.generate(9, (i) => i + 1);
      final operations = <OperationType>[
        OperationType.addition,
        OperationType.subtraction,
        OperationType.multiplication,
        OperationType.division,
      ];

      for (final grade in grades) {
        for (final operation in operations) {
          final expected = DifficultyConfig.expectedDifficultyStepForGrade(
            gradeLevel: grade,
            operation: operation,
          );

          for (final offset in <int>[-2, -1, 1, 2]) {
            final benchmark = DifficultyConfig.compareDifficultyStepToGrade(
              gradeLevel: grade,
              operation: operation,
              difficultyStep: expected + offset,
            );

            expect(
              benchmark.level,
              GradeBenchmarkLevel.inline,
              reason:
                  'Åk $grade, $operation, expected $expected, offset $offset should be inline',
            );
          }
        }
      }
    });
  });

  group('[Unit] DifficultyConfig – Parent suggested adjustments', () {
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

    test('skalning mot indikatorn: avstånd 0-2 => 1, 3-4 => 2, 5+ => 3', () {
      const over1 = GradeBenchmark(
        expectedStep: 5,
        actualStep: 6,
        delta: 1,
        level: GradeBenchmarkLevel.over,
      );
      expect(
        DifficultyConfig.parentSuggestedAdjustmentSteps(
          benchmark: over1,
          makeHarder: false,
        ),
        1,
      );

      const over3 = GradeBenchmark(
        expectedStep: 5,
        actualStep: 8,
        delta: 3,
        level: GradeBenchmarkLevel.over,
      );
      expect(
        DifficultyConfig.parentSuggestedAdjustmentSteps(
          benchmark: over3,
          makeHarder: false,
        ),
        2,
      );

      const under5 = GradeBenchmark(
        expectedStep: 7,
        actualStep: 2,
        delta: -5,
        level: GradeBenchmarkLevel.under,
      );
      expect(
        DifficultyConfig.parentSuggestedAdjustmentSteps(
          benchmark: under5,
          makeHarder: true,
        ),
        3,
      );
    });
  });
}
