// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  test('Curriculum: skriv ut 20 exempel per årskurs (Mix)', () {
    const earlyStep = 2;
    const lateStep = 9;
    const perStep = 10;

    AgeGroup ageGroupForGrade(int grade) {
      return DifficultyConfig.effectiveAgeGroup(
        fallback: AgeGroup.young,
        gradeLevel: grade,
      );
    }

    void printBatch({
      required int grade,
      required int step,
      required int seed,
    }) {
      final service = QuestionGeneratorService(random: Random(seed));
      final ageGroup = ageGroupForGrade(grade);

      print('');
      print(
        '--- Åk $grade | step=$step | seed=$seed | ageGroup=${ageGroup.name} ---',
      );

      for (var i = 0; i < perStep; i++) {
        final q = service.generateQuestion(
          ageGroup: ageGroup,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          difficultyStep: step,
          gradeLevel: grade,
        );

        // Ensure something reasonable, but this test's main purpose is output.
        expect(q.questionText.trim().isNotEmpty, isTrue);

        final text = q.questionText.replaceAll('\n', ' | ');
        print(
          '  ${i + 1}. ${q.operationType.name}: $text  =>  ${q.correctAnswer}',
        );
      }
    }

    print('=== Curriculum-exempel: Mix (20 per årskurs) ===');
    print(
      'Tidigt: step=$earlyStep ($perStep st), Sent: step=$lateStep ($perStep st)',
    );

    for (var grade = 1; grade <= 9; grade++) {
      printBatch(grade: grade, step: earlyStep, seed: grade * 1000 + earlyStep);
      printBatch(grade: grade, step: lateStep, seed: grade * 1000 + lateStep);
    }

    print('');
    print('=== KLAR ===');
  });
}
