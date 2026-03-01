import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/services/adaptive_difficulty_service.dart';

void main() {
  group('AdaptiveDifficultyService', () {
    late AdaptiveDifficultyService service;

    setUp(() {
      service = AdaptiveDifficultyService();
    });

    test('Unit (AdaptiveDifficultyService): beräknar träffsäkerhet korrekt',
        () {
      final results = [true, true, false, true, false];
      final successRate = service.calculateSuccessRate(results);

      expect(successRate, 0.6); // 3/5
    });

    test(
        'Unit (AdaptiveDifficultyService): behåller svårighetsgrad vid för lite data',
        () {
      final results = [true, false];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.easy,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.easy);
    });

    test(
        'Unit (AdaptiveDifficultyService): höjer svårighetsgrad vid hög träffsäkerhet',
        () {
      final results = [true, true, true, true, true];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.easy,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.medium);
    });

    test(
        'Unit (AdaptiveDifficultyService): sänker svårighetsgrad vid låg träffsäkerhet',
        () {
      final results = [false, false, true, false, false];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.medium,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.easy);
    });

    test('Unit (AdaptiveDifficultyService): höjer inte över hard', () {
      final results = [true, true, true, true, true];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.hard,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.hard);
    });

    test('Unit (AdaptiveDifficultyService): sänker inte under easy', () {
      final results = [false, false, false, false, false];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.easy,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.easy);
    });

    test('Unit (AdaptiveDifficultyService): steg - höjer vid hög träffsäkerhet',
        () {
      final results = [true, true, true, true, true];
      final step = service.suggestDifficultyStep(
        currentStep: 5,
        recentResults: results,
        minStep: 1,
        maxStep: 10,
      );

      expect(step, 6);
    });

    test(
        'Unit (AdaptiveDifficultyService): steg - sänker vid låg träffsäkerhet',
        () {
      final results = [false, false, true, false, false];
      final step = service.suggestDifficultyStep(
        currentStep: 5,
        recentResults: results,
        minStep: 1,
        maxStep: 10,
      );

      expect(step, 4);
    });

    test('Unit (AdaptiveDifficultyService): steg - klampar vid max', () {
      final results = [true, true, true, true, true];
      final step = service.suggestDifficultyStep(
        currentStep: 10,
        recentResults: results,
        minStep: 1,
        maxStep: 10,
      );

      expect(step, 10);
    });

    test('Unit (AdaptiveDifficultyService): steg - klampar vid min', () {
      final results = [false, false, false, false, false];
      final step = service.suggestDifficultyStep(
        currentStep: 1,
        recentResults: results,
        minStep: 1,
        maxStep: 10,
      );

      expect(step, 1);
    });
  });
}
