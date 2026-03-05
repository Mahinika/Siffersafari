import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

class _Observed {
  int total = 0;

  int add = 0;
  int sub = 0;
  int mul = 0;
  int div = 0;

  int time = 0;

  int m4Statistics = 0;
  int m4Probability = 0;
  int m4DiagramOrTableOrChartOrUnitOrGeom = 0;
  int m4Percent = 0;
  int m4NegativeNumbers = 0;

  int m5aPercent = 0;
  int m5aPower = 0;
  int m5aPrecedence = 0;

  int m5bLinearFunction = 0;
  int m5bGeometricTransformation = 0;
  int m5bAdvancedStatistics = 0;

  void see(OperationType op, String text, {required int grade}) {
    total++;

    switch (op) {
      case OperationType.addition:
        add++;
        break;
      case OperationType.subtraction:
        sub++;
        break;
      case OperationType.multiplication:
        mul++;
        break;
      case OperationType.division:
        div++;
        break;
      case OperationType.mixed:
        break;
    }

    // --- M4a: time
    if (text.contains('Klockan')) {
      time++;
      m4DiagramOrTableOrChartOrUnitOrGeom++;
      return;
    }

    // --- M4: statistics / probability / geometry / unit conversion
    if (text.contains('Typvärde') ||
        text.contains('Median') ||
        text.contains('Medelvärde') ||
        text.contains('Variationsbredd') ||
        text.contains('Tabell (statistik)') ||
        text.contains('Diagram (stapel)')) {
      m4Statistics++;
      m4DiagramOrTableOrChartOrUnitOrGeom++;
      return;
    }

    if (text.contains('Sannolikhet (diagram)') ||
        (text.contains('Röda:') && text.contains('Blå:'))) {
      m4Probability++;
      m4DiagramOrTableOrChartOrUnitOrGeom++;
      return;
    }

    if (text.contains('Enhetskonvertering') ||
        text.contains('Area (') ||
        text.contains('Omkrets (')) {
      m4DiagramOrTableOrChartOrUnitOrGeom++;
      return;
    }

    if (text.contains('Negativa tal')) {
      if (grade <= 6) {
        m4NegativeNumbers++;
      }
      return;
    }

    // --- M5a
    if (text.contains('% av')) {
      if (grade <= 6) {
        m4Percent++;
      } else {
        m5aPercent++;
      }
      return;
    }

    if (text.contains('Potenser') || text.contains('^')) {
      m5aPower++;
      return;
    }

    if (text.contains('Prioriteringsregler')) {
      m5aPrecedence++;
      return;
    }

    // --- M5b
    if (text.contains('Linjär funktion')) {
      m5bLinearFunction++;
      return;
    }

    if (text.contains('Geometrisk transformation') ||
        text.contains('Transformation:')) {
      m5bGeometricTransformation++;
      return;
    }

    if (text.contains('Variabel A:') || text.contains('korrelation')) {
      m5bAdvancedStatistics++;
      return;
    }
  }
}

void main() {
  test('Curriculum: Mix-logik per årskurs och step (1–10)', () {
    AgeGroup ageGroupForGrade(int grade) {
      return DifficultyConfig.effectiveAgeGroup(
        fallback: AgeGroup.young,
        gradeLevel: grade,
      );
    }

    int maxAbsForM5a(NumberRange range, int step) {
      final safeRangeMax = max(1, range.max);
      if (step <= 3) return min(20, safeRangeMax);
      if (step <= 6) return min(100, safeRangeMax);
      return min(1000, safeRangeMax);
    }

    void assertArithmeticRanges({
      required int grade,
      required int step,
      required OperationType op,
      required dynamic q,
      required String context,
    }) {
      // Special Mix question types (M4/M5/tid) are created with
      // operationType == mixed and do not follow operand/range rules.
      if (op == OperationType.mixed) return;

      final range = DifficultyConfig.curriculumNumberRangeForStep(
        gradeLevel: grade,
        operationType: op,
        difficultyStep: step,
      );

      final isM5a = grade >= 7;

      switch (op) {
        case OperationType.addition:
          expect(q.correctAnswer, q.operand1 + q.operand2, reason: context);

          if (isM5a) {
            final maxAbs = maxAbsForM5a(range, step);
            expect(
              q.operand1.abs(),
              lessThanOrEqualTo(maxAbs),
              reason: context,
            );
            expect(
              q.operand2.abs(),
              lessThanOrEqualTo(maxAbs),
              reason: context,
            );
            expect(
              !(q.operand1 == 0 && q.operand2 == 0),
              isTrue,
              reason: context,
            );
          } else {
            expect(
              q.operand1,
              inInclusiveRange(range.min, range.max),
              reason: context,
            );
            expect(
              q.operand2,
              inInclusiveRange(range.min, range.max),
              reason: context,
            );
            if (grade <= 3) {
              expect(
                q.correctAnswer,
                inInclusiveRange(range.min, range.max),
                reason: context,
              );
            }
          }
          return;

        case OperationType.subtraction:
          expect(q.correctAnswer, q.operand1 - q.operand2, reason: context);

          if (isM5a) {
            final maxAbs = maxAbsForM5a(range, step);
            expect(
              q.operand1.abs(),
              lessThanOrEqualTo(maxAbs),
              reason: context,
            );
            expect(q.operand2, inInclusiveRange(1, maxAbs), reason: context);
          } else {
            expect(
              q.operand1,
              inInclusiveRange(range.min, range.max),
              reason: context,
            );
            expect(
              q.operand2,
              inInclusiveRange(range.min, range.max),
              reason: context,
            );
            expect(q.correctAnswer, greaterThanOrEqualTo(0), reason: context);
            if (grade <= 3) {
              expect(
                q.correctAnswer,
                inInclusiveRange(range.min, range.max),
                reason: context,
              );
            }
          }
          return;

        case OperationType.multiplication:
          expect(q.correctAnswer, q.operand1 * q.operand2, reason: context);

          if (grade <= 3) {
            expect(q.operand1, inInclusiveRange(2, range.max), reason: context);
            expect(q.operand2, inInclusiveRange(2, range.max), reason: context);
            if (grade == 3 && step <= 6) {
              final minFactor =
                  q.operand1 < q.operand2 ? q.operand1 : q.operand2;
              expect(minFactor, lessThanOrEqualTo(10), reason: context);
            }
          } else {
            expect(q.operand1, inInclusiveRange(1, range.max), reason: context);
            expect(q.operand2, inInclusiveRange(1, range.max), reason: context);
            expect(
              q.operand1 <= 12 || q.operand2 <= 12,
              isTrue,
              reason: context,
            );
          }
          return;

        case OperationType.division:
          expect(q.operand2, isNot(0), reason: context);
          expect(q.operand1 % q.operand2, 0, reason: context);
          expect(q.correctAnswer, q.operand1 ~/ q.operand2, reason: context);

          if (grade <= 3) {
            expect(q.operand2, greaterThanOrEqualTo(2), reason: context);

            if (grade == 3 && step <= 6) {
              expect(q.operand2, lessThanOrEqualTo(10), reason: context);
              expect(q.correctAnswer, lessThanOrEqualTo(10), reason: context);
            } else {
              expect(q.operand2, lessThanOrEqualTo(range.max), reason: context);
              expect(
                q.correctAnswer,
                lessThanOrEqualTo(range.max),
                reason: context,
              );
            }
          } else {
            expect(q.operand2, inInclusiveRange(1, 12), reason: context);
            expect(
              q.correctAnswer,
              inInclusiveRange(1, range.max),
              reason: context,
            );
          }
          return;

        case OperationType.mixed:
          return;
      }
    }

    _Observed observe({
      required int grade,
      required int step,
      required List<int> seeds,
      required int samplesPerSeed,
    }) {
      final obs = _Observed();
      final ageGroup = ageGroupForGrade(grade);

      for (final seed in seeds) {
        final service = QuestionGeneratorService(random: Random(seed));
        for (var i = 0; i < samplesPerSeed; i++) {
          final q = service.generateQuestion(
            ageGroup: ageGroup,
            operationType: OperationType.mixed,
            difficulty: DifficultyLevel.medium,
            difficultyStep: step,
            gradeLevel: grade,
            missingNumberEnabledOverride: false,
          );

          final text = (q.promptText ?? q.questionText).trim();
          expect(text, isNotEmpty);

          assertArithmeticRanges(
            grade: grade,
            step: step,
            op: q.operationType,
            q: q,
            context:
                'Åk $grade step $step (seed=$seed sample=$i op=${q.operationType.name})',
          );
          obs.see(q.operationType, text, grade: grade);
        }
      }

      expect(obs.total, seeds.length * samplesPerSeed);
      return obs;
    }

    void expectNever(int actual, String what, {String? context}) {
      expect(
        actual,
        0,
        reason: context == null
            ? 'Expected never: $what'
            : '$context: Expected never: $what',
      );
    }

    void expectSometimes(int actual, String what, {String? context}) {
      expect(
        actual,
        greaterThan(0),
        reason: context == null
            ? 'Expected sometimes: $what'
            : '$context: Expected sometimes: $what (but saw 0)',
      );
    }

    // Deterministic but robust against “unlucky” single-seed runs.
    const samplesPerSeed = 160;
    const seedCount = 3;

    for (var grade = 1; grade <= 9; grade++) {
      for (var step = 1; step <= 10; step++) {
        final ctx = 'Åk $grade step $step';
        final base = grade * 10000 + step * 10;
        final seeds = List<int>.generate(seedCount, (i) => base + i);

        final obs = observe(
          grade: grade,
          step: step,
          seeds: seeds,
          samplesPerSeed: samplesPerSeed,
        );

        // --- Base operation visibility rules (Mix)
        if (grade <= 2) {
          expectNever(obs.mul, '×', context: ctx);
          expectNever(obs.div, '÷', context: ctx);
        }

        if (grade == 3) {
          if (step <= 3) {
            expectNever(obs.mul, '×', context: ctx);
            expectNever(obs.div, '÷', context: ctx);
          } else if (step <= 6) {
            expectSometimes(obs.mul, '×', context: ctx);
            expectNever(obs.div, '÷', context: ctx);
          } else {
            // step 7–10: ÷ is allowed in Mix (weighted).
            expectSometimes(obs.mul, '×', context: ctx);
            expectSometimes(obs.div, '÷', context: ctx);
          }
        }

        // --- Time questions (M4a) gating
        if (grade == 2) {
          if (step <= 4) {
            expectNever(obs.time, 'Tid (Klockan)', context: ctx);
          } else {
            expectSometimes(obs.time, 'Tid (Klockan)', context: ctx);
          }
        }
        if (grade == 3) {
          if (step <= 3) {
            expectNever(obs.time, 'Tid (Klockan)', context: ctx);
          } else {
            expectSometimes(obs.time, 'Tid (Klockan)', context: ctx);
          }
        }
        if (grade != 2 && grade != 3) {
          expectNever(obs.time, 'Tid (Klockan)', context: ctx);
        }

        // --- M4 (Åk 4–6) special Mix types should exist; M5 should not.
        if (grade >= 4 && grade <= 6) {
          expectSometimes(
            obs.m4Statistics +
                obs.m4Probability +
                obs.m4DiagramOrTableOrChartOrUnitOrGeom,
            'M4 special (statistik/sannolikhet/diagram/enheter/geometri)',
            context: ctx,
          );

          // Skolverket inkluderar procent och negativa tal i Åk 4–6.
          // Vi introducerar detta försiktigt: endast Åk 5–6, och bara på höga steps.
          if (grade >= 5 && step >= 9) {
            expectSometimes(
              obs.m4Percent,
              'M4 procent (Åk 5–6, sent)',
              context: ctx,
            );
            expectSometimes(
              obs.m4NegativeNumbers,
              'M4 negativa tal (Åk 5–6, sent)',
              context: ctx,
            );
          } else {
            expectNever(obs.m4Percent, 'M4 procent', context: ctx);
            expectNever(obs.m4NegativeNumbers, 'M4 negativa tal', context: ctx);
          }

          expectNever(obs.m5aPercent, 'M5a procent', context: ctx);
          expectNever(obs.m5aPower, 'M5a potenser', context: ctx);
          expectNever(
            obs.m5aPrecedence,
            'M5a prioriteringsregler',
            context: ctx,
          );
          expectNever(
            obs.m5bLinearFunction,
            'M5b linjär funktion',
            context: ctx,
          );
          expectNever(
            obs.m5bGeometricTransformation,
            'M5b transformation',
            context: ctx,
          );
          expectNever(
            obs.m5bAdvancedStatistics,
            'M5b avancerad statistik',
            context: ctx,
          );
        }

        // --- M5a/M5b (Åk 7–9) Mix types should exist.
        if (grade >= 7) {
          expectNever(obs.m4Percent, 'M4 procent', context: ctx);
          expectNever(obs.m4NegativeNumbers, 'M4 negativa tal', context: ctx);

          expectSometimes(obs.m5aPercent, 'M5a procent', context: ctx);
          expectSometimes(
            obs.m5aPrecedence,
            'M5a prioriteringsregler',
            context: ctx,
          );

          if (grade == 7) {
            // Power is only enabled for grade 8+.
            expectNever(obs.m5aPower, 'M5a potenser', context: ctx);
          } else {
            expectSometimes(obs.m5aPower, 'M5a potenser', context: ctx);
          }

          if (step < 8) {
            expectNever(
              obs.m5bLinearFunction,
              'M5b linjär funktion',
              context: ctx,
            );
            expectNever(
              obs.m5bGeometricTransformation,
              'M5b transformation',
              context: ctx,
            );
            expectNever(
              obs.m5bAdvancedStatistics,
              'M5b avancerad statistik',
              context: ctx,
            );
          } else {
            // At step 8+, at least one of the M5b types should appear.
            expectSometimes(
              obs.m5bLinearFunction +
                  obs.m5bGeometricTransformation +
                  obs.m5bAdvancedStatistics,
              'M5b (linjär/transform/avancerad statistik)',
              context: ctx,
            );
          }
        } else {
          // Below grade 7, none of M5 should appear.
          expectNever(obs.m5aPercent, 'M5a procent', context: ctx);
          expectNever(obs.m5aPower, 'M5a potenser', context: ctx);
          expectNever(
            obs.m5aPrecedence,
            'M5a prioriteringsregler',
            context: ctx,
          );
          expectNever(
            obs.m5bLinearFunction,
            'M5b linjär funktion',
            context: ctx,
          );
          expectNever(
            obs.m5bGeometricTransformation,
            'M5b transformation',
            context: ctx,
          );
          expectNever(
            obs.m5bAdvancedStatistics,
            'M5b avancerad statistik',
            context: ctx,
          );
        }
      }
    }
  });
}
