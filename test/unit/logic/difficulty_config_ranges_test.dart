import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('[Unit] DifficultyConfig – Curriculum number ranges (Åk 4–6)', () {
    test('Åk 4 (+): step-tabell är monotont ökande och slutar på 10 000', () {
      final maxByStep = List<int>.generate(
        10,
        (i) => DifficultyConfig.curriculumNumberRangeForStep(
          gradeLevel: 4,
          operationType: OperationType.addition,
          difficultyStep: i + 1,
        ).max,
      );

      expect(maxByStep.first, 20);
      expect(maxByStep.last, 10000);
      for (var i = 1; i < maxByStep.length; i++) {
        expect(maxByStep[i], greaterThanOrEqualTo(maxByStep[i - 1]));
      }
    });

    test('Åk 5 (−): step-tabell är monotont ökande och slutar på 100 000', () {
      final maxByStep = List<int>.generate(
        10,
        (i) => DifficultyConfig.curriculumNumberRangeForStep(
          gradeLevel: 5,
          operationType: OperationType.subtraction,
          difficultyStep: i + 1,
        ).max,
      );

      expect(maxByStep.first, 50);
      expect(maxByStep.last, 100000);
      for (var i = 1; i < maxByStep.length; i++) {
        expect(maxByStep[i], greaterThanOrEqualTo(maxByStep[i - 1]));
      }
    });

    test('Åk 6 (+): step-tabell slutar på 100 000', () {
      final range = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: 6,
        operationType: OperationType.addition,
        difficultyStep: 10,
      );

      expect(range.max, 100000);
    });

    test('multiplikation skalar upp till två-/tresiffriga faktorer', () {
      final r4 = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: 4,
        operationType: OperationType.multiplication,
        difficultyStep: DifficultyConfig.maxDifficultyStep,
      );
      expect(r4.max, 99);

      final r6 = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: 6,
        operationType: OperationType.multiplication,
        difficultyStep: DifficultyConfig.maxDifficultyStep,
      );
      expect(r6.max, 299);
    });

    test('division skalar upp men hålls mer konservativ än multiplikation', () {
      final r4 = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: 4,
        operationType: OperationType.division,
        difficultyStep: DifficultyConfig.maxDifficultyStep,
      );
      expect(r4.max, 20);

      final r6 = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: 6,
        operationType: OperationType.division,
        difficultyStep: DifficultyConfig.maxDifficultyStep,
      );
      expect(r6.max, 100);
    });
  });

  group('[Unit] DifficultyConfig – Time limits and questions', () {
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

    test('getQuestionsPerSession returnerar förväntat antal per åldersgrupp',
        () {
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.young), 8);
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.middle), 10);
      expect(DifficultyConfig.getQuestionsPerSession(AgeGroup.older), 12);
    });
  });

  group('[Unit] DifficultyConfig – Number ranges', () {
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
