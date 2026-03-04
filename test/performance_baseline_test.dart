import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('Performance baseline', () {
    test('question generation baseline (2000 frågor)', () {
      final service = QuestionGeneratorService(random: Random(42));
      final sw = Stopwatch()..start();

      for (var i = 0; i < 2000; i++) {
        service.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.addition,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 4,
          difficultyStep: 5,
        );
      }

      sw.stop();
      // Generös gräns för CI/lågprestanda runners.
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('difficulty recommendation baseline (100k beräkningar)', () {
      final sw = Stopwatch()..start();

      for (var i = 0; i < 100000; i++) {
        DifficultyConfig.recommendedDifficultyStepForTraining(
          currentStep: 5,
          averageSuccessRate: (i % 100) / 100.0,
        );
      }

      sw.stop();
      // Också med generös gräns.
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
