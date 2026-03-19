import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/utils/retry.dart';

void main() {
  group('[Unit] retryAsync', () {
    test('försöker igen tills operationen lyckas', () async {
      var calls = 0;
      final logs = <String>[];

      final value = await retryAsync<String>(
        label: 'eventual-success',
        maxAttempts: 3,
        initialDelay: Duration.zero,
        operation: () async {
          calls++;
          if (calls < 3) {
            throw StateError('temporary');
          }
          return 'ok';
        },
        log: logs.add,
      );

      expect(value, 'ok');
      expect(calls, 3);
      expect(logs.length, 2);
    });

    test('respekterar shouldRetry och avbryter direkt när false', () async {
      var calls = 0;

      await expectLater(
        () => retryAsync<void>(
          label: 'no-retry',
          maxAttempts: 4,
          initialDelay: Duration.zero,
          operation: () async {
            calls++;
            throw UnsupportedError('fatal');
          },
          shouldRetry: (error) => error is! UnsupportedError,
        ),
        throwsA(isA<UnsupportedError>()),
      );

      expect(calls, 1);
    });

    test('kastar ArgumentError om maxAttempts är <= 0', () async {
      await expectLater(
        () => retryAsync<void>(
          label: 'invalid-attempts',
          maxAttempts: 0,
          operation: () async {},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
