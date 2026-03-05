import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
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
        'pin_lockout_until',
        DateTime.now()
            .subtract(const Duration(seconds: 1))
            .millisecondsSinceEpoch,
      );
      await storage.saveSetting('pin_failed_attempts', 5);

      final ok = await service.verifyPin('0000');
      expect(ok, isFalse);

      // Lockout cleared, attempts reset then incremented to 1 for the wrong try.
      expect(service.getRemainingAttempts(), 4);
      expect(service.getLockoutRemainingMinutes(), isNull);
    });
  });

  group('[Unit] ParentPinService – Recovery codes', () {
    test('setupPinRecovery stores hashed config and returns plaintext codes',
        () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      final codes = await service.setupPinRecovery(
        securityQuestion: 'Q',
        securityAnswer: 'My Answer',
      );

      expect(codes, hasLength(6));
      // Regression: backup codes must be unique within a batch.
      expect(codes.toSet(), hasLength(6));
      final codeFormat = RegExp(r'^[A-Z0-9]{8}$');
      for (final code in codes) {
        expect(code, matches(codeFormat));
      }

      expect(service.hasRecoveryConfigured(), isTrue);
      expect(service.getSecurityQuestion(), 'Q');
    });

    test('verifySecurityAnswer is case-insensitive and tracks remaining codes',
        () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      final codes = await service.setupPinRecovery(
        securityQuestion: 'Q',
        securityAnswer: 'My Answer',
      );

      final correct1 = await service.verifySecurityAnswer('my answer');
      expect(correct1.$1, isTrue);
      expect(correct1.$2, 6);

      final raw = storage.getSetting('pin_recovery_config');
      expect(raw, isA<Map>());

      final rawMap = raw as Map;
      final storedHashes = List<String>.from(rawMap['backupCodes'] as List);
      expect(storedHashes, hasLength(6));

      final matchingCode = codes.firstWhere(
        (code) => storedHashes.any((hash) => BCrypt.checkpw(code, hash)),
      );

      // Regression: backup code redemption is case-insensitive.
      final used =
          await service.verifyAndUseBackupCode(matchingCode.toLowerCase());
      expect(used, isTrue);

      final correct2 = await service.verifySecurityAnswer('MY ANSWER');
      expect(correct2.$1, isTrue);
      expect(correct2.$2, 5);

      final reused = await service.verifyAndUseBackupCode(matchingCode);
      expect(reused, isFalse);

      final wrong = await service.verifyAndUseBackupCode('ZZZZZZZZ');
      expect(wrong, isFalse);
    });

    test('regenerateBackupCodes invalidates old codes and resets used flags',
        () async {
      final storage = _InMemorySettingsRepository();
      final service = ParentPinService(storage);

      final oldCodes = await service.setupPinRecovery(
        securityQuestion: 'Q',
        securityAnswer: 'My Answer',
      );

      final newCodes = await service.regenerateBackupCodes();
      expect(newCodes, hasLength(6));

      // Old codes should no longer match.
      final oldStillWorks =
          await service.verifyAndUseBackupCode(oldCodes.first);
      expect(oldStillWorks, isFalse);

      final newWorks = await service.verifyAndUseBackupCode(newCodes.first);
      expect(newWorks, isTrue);
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
