import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/domain/services/profile_backup_service.dart';

void main() {
  group('[Unit] ProfileBackupService', () {
    late ProfileBackupService service;

    setUp(() {
      service = ProfileBackupService();
    });

    test('encode/decode roundtrip fungerar', () {
      const backup = ProfileBackup(
        schemaVersion: 1,
        userId: 'u1',
        userData: <String, dynamic>{'name': 'Test', 'gradeLevel': 3},
        quizHistory: <Map<String, dynamic>>[
          <String, dynamic>{'sessionId': 's1', 'score': 7},
        ],
      );

      final json = service.encode(backup);
      final decoded = service.decode(json);

      expect(decoded.schemaVersion, 1);
      expect(decoded.userId, 'u1');
      expect(decoded.userData['name'], 'Test');
      expect(decoded.quizHistory.length, 1);
      expect(decoded.quizHistory.first['sessionId'], 's1');
    });

    test('decode failar pa korrupt json', () {
      expect(
        () => service.decode('{not-json}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode failar pa unsupported schema version', () {
      const payload =
          '{"schemaVersion":99,"userId":"u1","userData":{},"quizHistory":[]}';

      expect(
        () => service.decode(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode failar vid saknade obligatoriska falt', () {
      const payload = '{"schemaVersion":1,"userData":{},"quizHistory":[]}';

      expect(
        () => service.decode(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode failar om userData.name saknas eller ar tom', () {
      const payloadMissingName =
          '{"schemaVersion":1,"userId":"u1","userData":{},"quizHistory":[]}';
      const payloadEmptyName =
          '{"schemaVersion":1,"userId":"u1","userData":{"name":""},"quizHistory":[]}';

      expect(
        () => service.decode(payloadMissingName),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.decode(payloadEmptyName),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode failar om quizHistory-entry saknar giltigt sessionId', () {
      const payload =
          '{"schemaVersion":1,"userId":"u1","userData":{"name":"Test"},"quizHistory":[{"score":7}]}';

      expect(
        () => service.decode(payload),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
