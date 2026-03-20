import 'package:flutter_test/flutter_test.dart';
import 'package:siffersafari/core/constants/settings_keys.dart';
import 'package:siffersafari/data/repositories/local_storage_repository.dart';
import 'package:siffersafari/domain/services/parent_pin_service.dart';

class _InMemorySettingsRepository extends LocalStorageRepository {
  final Map<String, dynamic> _settings = {};

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings.containsKey(key) ? _settings[key] : defaultValue;
  }

  @override
  Future<void> deleteSetting(String key) async {
    _settings.remove(key);
  }
}

void main() {
  group('[Unit] ParentPinService – PIN authentication', () {
    test('verifyPin returns false when no PIN is set', () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      final isCorrect = await service.verifyPin('1234');
      expect(isCorrect, isFalse);
    });

    test('setPin + verifyPin accepts correct PIN and resets attempts',
        () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      await service.setPin('1234');

      final wrong = await service.verifyPin('0000');
      expect(wrong, isFalse);
      expect(service.getRemainingAttempts(), 4);

      final ok = await service.verifyPin('1234');
      expect(ok, isTrue);
      expect(service.getRemainingAttempts(), 5);
    });

    test('wrong PIN triggers lockout after 5 attempts', () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      await service.setPin('1234');

      for (var i = 0; i < 4; i++) {
        final ok = await service.verifyPin('0000');
        expect(ok, isFalse);
      }

      await expectLater(
        () => service.verifyPin('0000'),
        throwsA(
          isA<PinLockoutException>().having(
            (e) => e.remainingMinutes,
            'remainingMinutes',
            5,
          ),
        ),
      );

      await expectLater(
        () => service.verifyPin('1234'),
        throwsA(
          isA<PinLockoutException>().having(
            (e) => e.remainingMinutes,
            'remainingMinutes',
            inInclusiveRange(1, 5),
          ),
        ),
      );
    });

    test('expired lockout is cleared on next verification', () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      await service.setPin('1234');

      // Simulate a past lockout.
      await storage.saveSetting(
        SettingsKeys.parentPinLockoutUntil,
        DateTime.now()
            .subtract(const Duration(seconds: 1))
            .millisecondsSinceEpoch,
      );
      await storage.saveSetting(SettingsKeys.parentPinFailedAttempts, 5);

      final ok = await service.verifyPin('0000');
      expect(ok, isFalse);

      // Lockout cleared, attempts reset then incremented to 1 for the wrong try.
      expect(service.getRemainingAttempts(), 4);
      expect(service.getLockoutRemainingMinutes(), isNull);
    });
  });

  group('[Unit] ParentPinService – Security question recovery', () {
    test('setupPinRecovery stores security question + hashed answer', () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      await service.setupPinRecovery(
        securityQuestion: 'Q',
        securityAnswer: 'My Answer',
      );

      expect(service.hasRecoveryConfigured(), isTrue);
      expect(service.getSecurityQuestion(), 'Q');

      final raw = storage.getSetting(SettingsKeys.parentPinRecoveryConfig);
      expect(raw, isA<Map>());
      final rawMap = raw as Map;
      expect(rawMap['securityQuestion'], 'Q');
      final hash = rawMap['securityAnswerHash'] as String;
      expect(hash.isNotEmpty, isTrue);
      expect(hash, isNot('my answer'));
    });

    test('verifySecurityAnswer is case-insensitive', () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      await service.setupPinRecovery(
        securityQuestion: 'Q',
        securityAnswer: 'My Answer',
      );

      final correct = await service.verifySecurityAnswer('MY ANSWER');
      expect(correct, isTrue);

      final wrong = await service.verifySecurityAnswer('fel svar');
      expect(wrong, isFalse);
    });

    test('clearRecoveryConfig removes config', () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      await service.setupPinRecovery(
        securityQuestion: 'Q',
        securityAnswer: 'My Answer',
      );

      expect(service.hasRecoveryConfigured(), isTrue);
      await service.clearRecoveryConfig();
      expect(service.hasRecoveryConfigured(), isFalse);
    });
  });
}
