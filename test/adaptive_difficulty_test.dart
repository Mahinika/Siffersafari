import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/services/adaptive_difficulty_service.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';

void main() {
  group('AdaptiveDifficultyService', () {
    late AdaptiveDifficultyService service;

    setUp(() {
      service = AdaptiveDifficultyService();
    });

    test('calculates success rate correctly', () {
      final results = [true, true, false, true, false];
      final successRate = service.calculateSuccessRate(results);

      expect(successRate, 0.6); // 3/5
    });

    test('suggests same difficulty with insufficient data', () {
      final results = [true, false];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.easy,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.easy);
    });

    test('suggests increased difficulty with high success rate', () {
      final results = [true, true, true, true, true];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.easy,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.medium);
    });

    test('suggests decreased difficulty with low success rate', () {
      final results = [false, false, true, false, false];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.medium,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.easy);
    });

    test('does not increase beyond hard difficulty', () {
      final results = [true, true, true, true, true];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.hard,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.hard);
    });

    test('does not decrease below easy difficulty', () {
      final results = [false, false, false, false, false];
      final suggestion = service.suggestDifficulty(
        currentDifficulty: DifficultyLevel.easy,
        recentResults: results,
      );

      expect(suggestion, DifficultyLevel.easy);
    });
  });
}
