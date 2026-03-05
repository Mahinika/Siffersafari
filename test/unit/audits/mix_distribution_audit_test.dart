import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/services/question_generator_service.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/domain/enums/difficulty_level.dart';
import 'package:siffersafari/domain/enums/operation_type.dart';

String _classifyPrompt(String? promptText) {
  if (promptText == null) return 'normal';

  if (promptText.startsWith('Typvärde') ||
      promptText.startsWith('Median') ||
      promptText.startsWith('Medelvärde') ||
      promptText.startsWith('Variationsbredd') ||
      promptText.startsWith('Tabell (statistik)') ||
      promptText.startsWith('Diagram (stapel)') ||
      promptText.startsWith('Sannolikhet (diagram)') ||
      promptText.startsWith('Enhetskonvertering') ||
      promptText.startsWith('Area') ||
      promptText.startsWith('Omkrets')) {
    return 'm4_stats';
  }

  if (promptText.startsWith('Chans (%)')) return 'm4_prob_percent';
  if (promptText.startsWith('Skillnad i chans')) return 'm4_prob_compare';
  if (promptText.startsWith('Kombinationer')) return 'm4_combinatorics';

  // Late M4 additions (Åk 5–6, high steps): percent and negative numbers.
  if (promptText.startsWith('Procent = ?')) return 'm4_percent_of';
  if (promptText.startsWith('Negativa tal = ?')) return 'm4_negative_numbers';

  // M5a features
  if (promptText.startsWith('Potenser = ?')) return 'm5a_power';
  if (promptText.startsWith('Prioriteringsregler = ?')) return 'm5a_precedence';

  // M5b features
  if (promptText.startsWith('Linjär funktion = ?')) return 'm5b_linear';
  if (promptText.startsWith('Geometrisk transformation = ?')) {
    return 'm5b_geometric';
  }
  if (promptText.startsWith('Statistik = ?')) return 'm5b_advanced_stats';

  // M4a features
  if (promptText.contains('Klockan visar')) return 'm4a_time';

  return 'other_prompt';
}

double _expectedStatsChanceForStep(int step) {
  if (step <= 3) return 0.10;
  if (step <= 6) return 0.12;
  return 0.12;
}

double _expectedProbChanceForStep(int step) {
  if (step <= 3) return 0.10;
  if (step <= 6) return 0.12;
  return 0.12;
}

double _expectedLateM4PercentChance({
  required int grade,
  required int step,
}) {
  return grade >= 5 && step >= 9 ? 0.06 : 0.0;
}

double _expectedLateM4NegativeChance({
  required int grade,
  required int step,
}) {
  return grade >= 5 && step >= 9 ? 0.04 : 0.0;
}

void main() {
  group('[Unit] Mix distribution – Audit', () {
    test('Åk 4–6: M4-andel i Mix ligger nära förväntat per step-bucket', () {
      // This test is intentionally deterministic and prints a small report.
      // Goal: quickly catch accidental changes in Mix distribution.
      const seeds = <int>[101, 202, 303];
      const grades = <int>[4, 5, 6];
      const stepBuckets = <int>[2, 5, 9]; // represents 1–3, 4–6, 7–10
      const nPerCase = 5000;

      for (final grade in grades) {
        for (final step in stepBuckets) {
          final expectedStats = _expectedStatsChanceForStep(step);
          final expectedProb = _expectedProbChanceForStep(step);
          final expectedLatePercent =
              _expectedLateM4PercentChance(grade: grade, step: step);
          final expectedLateNegative =
              _expectedLateM4NegativeChance(grade: grade, step: step);

          final expectedSpecial = expectedStats +
              expectedProb +
              expectedLatePercent +
              expectedLateNegative;

          var total = 0;
          var stats = 0;
          var probPercent = 0;
          var probCompare = 0;
          var combinatorics = 0;
          var percentOf = 0;
          var negativeNumbers = 0;
          var normal = 0;
          var otherPrompt = 0;

          for (final seed in seeds) {
            final service = QuestionGeneratorService(
              random: Random(seed),
              wordProblemsEnabled: false,
              missingNumberEnabled: false,
            );

            for (var i = 0; i < nPerCase; i++) {
              final q = service.generateQuestion(
                ageGroup: AgeGroup.middle,
                operationType: OperationType.mixed,
                difficulty: DifficultyLevel.easy,
                gradeLevel: grade,
                difficultyStep: step,
              );

              total++;
              final cls = _classifyPrompt(q.promptText);
              switch (cls) {
                case 'm4_stats':
                  stats++;
                  break;
                case 'm4_prob_percent':
                  probPercent++;
                  break;
                case 'm4_prob_compare':
                  probCompare++;
                  break;
                case 'm4_combinatorics':
                  combinatorics++;
                  break;
                case 'm4_percent_of':
                  percentOf++;
                  break;
                case 'm4_negative_numbers':
                  negativeNumbers++;
                  break;
                case 'normal':
                  normal++;
                  break;
                default:
                  otherPrompt++;
                  break;
              }
            }
          }

          final statsPct = stats / total;
          final probPct = (probPercent + probCompare + combinatorics) / total;
          final lateM4Pct = (percentOf + negativeNumbers) / total;
          final specialPct = statsPct + probPct;

          // Small report (visible in `flutter test -r expanded`).
          // Example: Åk 5 step 9: special=0.281 stats=0.142 prob=0.139 (...)
          // ignore: avoid_print
          print(
            'Mix audit Åk $grade step $step: '
            'special=${specialPct.toStringAsFixed(3)} '
            'stats=${statsPct.toStringAsFixed(3)} '
            'prob=${probPct.toStringAsFixed(3)} '
            '(percent=${(probPercent / total).toStringAsFixed(3)} '
            'compare=${(probCompare / total).toStringAsFixed(3)} '
            'comb=${(combinatorics / total).toStringAsFixed(3)} '
            'late=${lateM4Pct.toStringAsFixed(3)}) '
            'normal=${(normal / total).toStringAsFixed(3)} '
            'otherPrompt=${(otherPrompt / total).toStringAsFixed(3)}',
          );

          // Guardrails: allow some drift but catch big accidental changes.
          const tolerance = 0.03;
          expect(
            ((specialPct + lateM4Pct) - expectedSpecial).abs(),
            lessThanOrEqualTo(tolerance),
            reason:
                'Special-andel ska vara nära ${expectedSpecial.toStringAsFixed(2)} '
                'för step $step (Åk $grade).',
          );
          expect(
            (statsPct - expectedStats).abs(),
            lessThanOrEqualTo(tolerance),
            reason:
                'Stats-andel ska vara nära ${expectedStats.toStringAsFixed(2)} '
                'för step $step (Åk $grade).',
          );
          expect(
            (probPct - expectedProb).abs(),
            lessThanOrEqualTo(tolerance),
            reason:
                'Prob-andel ska vara nära ${expectedProb.toStringAsFixed(2)} '
                'för step $step (Åk $grade).',
          );

          // Sanity: we should not generate unknown prompt types here.
          expect(otherPrompt, 0);
        }
      }
    });
  });
}
