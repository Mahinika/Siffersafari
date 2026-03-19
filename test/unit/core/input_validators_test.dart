import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/utils/input_validators.dart';

void main() {
  group('[Unit] InputValidators', () {
    test('validatePin accepterar endast 4-6 siffror', () {
      expect(InputValidators.validatePin('1234'), isNull);
      expect(InputValidators.validatePin('123456'), isNull);

      expect(InputValidators.validatePin('123'), 'PIN måste vara 4-6 siffror');
      expect(
        InputValidators.validatePin('1234567'),
        'PIN måste vara 4-6 siffror',
      );
      expect(
        InputValidators.validatePin('12a4'),
        'PIN får bara innehålla siffror',
      );
    });

    test('validateProfileName trimmar och blockerar otillåtna tecken', () {
      expect(InputValidators.validateProfileName('  Nora  '), isNull);
      expect(
        InputValidators.validateProfileName('     '),
        'Namn kan inte bara innehålla mellanslag',
      );
      expect(
        InputValidators.validateProfileName('Alice<3'),
        'Namn innehåller otillåtna tecken',
      );
    });

    test('sanitize helpers tar bort oönskade tecken och trimmar', () {
      expect(InputValidators.sanitizePin('12-3a4'), '1234');
      expect(InputValidators.sanitizeProfileName('  Alex  '), 'Alex');
      expect(InputValidators.sanitizeSecurityAnswer('  Mat  '), 'Mat');
    });
  });
}
