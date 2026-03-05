import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

void main() {
  group('[Unit] DifficultyConfig.effectiveAllowedOperations', () {
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
}
