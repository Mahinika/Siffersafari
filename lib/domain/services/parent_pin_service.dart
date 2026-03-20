import 'package:bcrypt/bcrypt.dart';

import '../../core/constants/settings_keys.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../entities/pin_recovery_config.dart';

/// Service for secure parent PIN management with hashing and rate limiting.
class ParentPinService {
  ParentPinService(this._storage);

  final LocalStorageRepository _storage;

  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  /// Hash a PIN using BCrypt (adaptive hashing with built-in salt).
  String _hashPin(String pin) {
    // Generate salt and hash in one operation (cost factor 10 is standard)
    return BCrypt.hashpw(pin, BCrypt.gensalt(logRounds: 10));
  }

  /// Check if PIN exists (has been set).
  bool hasPinSet() {
    final hash = _storage.getSetting(SettingsKeys.parentPinHash) as String?;
    return hash != null && hash.isNotEmpty;
  }

  /// Save a new PIN (hashed).
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.saveSetting(SettingsKeys.parentPinHash, hash);
    // Reset failed attempts when setting new PIN
    await _storage.saveSetting(SettingsKeys.parentPinFailedAttempts, 0);
    await _storage.deleteSetting(SettingsKeys.parentPinLockoutUntil);
  }

  /// Verify if provided PIN matches stored hash.
  /// Returns true if correct, false if wrong or locked out.
  /// Throws [PinLockoutException] if currently locked out.
  Future<bool> verifyPin(String pin) async {
    // Check lockout
    final lockoutUntil =
        _storage.getSetting(SettingsKeys.parentPinLockoutUntil) as int?;
    if (lockoutUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < lockoutUntil) {
        final remainingMinutes = ((lockoutUntil - now) / 1000 / 60).ceil();
        throw PinLockoutException(remainingMinutes);
      } else {
        // Lockout expired, clear it
        await _storage.deleteSetting(SettingsKeys.parentPinLockoutUntil);
        await _storage.saveSetting(SettingsKeys.parentPinFailedAttempts, 0);
      }
    }

    final storedHash =
        _storage.getSetting(SettingsKeys.parentPinHash) as String?;
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    // Use BCrypt.checkpw for secure constant-time comparison
    final isCorrect = BCrypt.checkpw(pin, storedHash);

    if (isCorrect) {
      // Reset failed attempts on successful login
      await _storage.saveSetting(SettingsKeys.parentPinFailedAttempts, 0);
      await _storage.deleteSetting(SettingsKeys.parentPinLockoutUntil);
      return true;
    } else {
      // Increment failed attempts
      final failedAttempts =
          (_storage.getSetting(SettingsKeys.parentPinFailedAttempts) as int? ??
                  0) +
              1;
      await _storage.saveSetting(
        SettingsKeys.parentPinFailedAttempts,
        failedAttempts,
      );

      if (failedAttempts >= _maxFailedAttempts) {
        // Lock out
        final lockoutUntil =
            DateTime.now().add(_lockoutDuration).millisecondsSinceEpoch;
        await _storage.saveSetting(
          SettingsKeys.parentPinLockoutUntil,
          lockoutUntil,
        );
        throw PinLockoutException(_lockoutDuration.inMinutes);
      }

      return false;
    }
  }

  /// Get remaining failed attempts before lockout.
  int getRemainingAttempts() {
    final failedAttempts =
        _storage.getSetting(SettingsKeys.parentPinFailedAttempts) as int? ?? 0;
    final remaining = _maxFailedAttempts - failedAttempts;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if currently locked out and return remaining minutes.
  int? getLockoutRemainingMinutes() {
    final lockoutUntil =
        _storage.getSetting(SettingsKeys.parentPinLockoutUntil) as int?;
    if (lockoutUntil == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= lockoutUntil) return null;

    return ((lockoutUntil - now) / 1000 / 60).ceil();
  }

  // ============================================================================
  // PIN RECOVERY METHODS (Security Question)
  // ============================================================================

  /// Check if recovery config is set up
  bool hasRecoveryConfigured() {
    final config = _getRecoveryConfig();
    return config != null;
  }

  /// Get the stored recovery config (or null if not set)
  PinRecoveryConfig? _getRecoveryConfig() {
    final raw = _storage.getSetting(SettingsKeys.parentPinRecoveryConfig);
    if (raw is! Map) return null;

    try {
      return PinRecoveryConfig(
        securityQuestion: raw['securityQuestion'] as String? ?? '',
        securityAnswerHash: raw['securityAnswerHash'] as String? ?? '',
        createdAt: raw['createdAt'] is String
            ? DateTime.tryParse(raw['createdAt'] as String)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Save recovery config to storage
  Future<void> _saveRecoveryConfig(PinRecoveryConfig config) async {
    await _storage.saveSetting(SettingsKeys.parentPinRecoveryConfig, {
      'securityQuestion': config.securityQuestion,
      'securityAnswerHash': config.securityAnswerHash,
      'createdAt': config.createdAt?.toIso8601String(),
    });
  }

  /// Setup PIN recovery on first PIN creation using a security question.
  Future<void> setupPinRecovery({
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    // Hash the security answer
    final answerHash = _hashPin(securityAnswer.trim().toLowerCase());

    // Store recovery config for security question based recovery.
    final config = PinRecoveryConfig(
      securityQuestion: securityQuestion,
      securityAnswerHash: answerHash,
      createdAt: DateTime.now(),
    );

    await _saveRecoveryConfig(config);
  }

  /// Verify security question answer.
  Future<bool> verifySecurityAnswer(String answer) async {
    final config = _getRecoveryConfig();
    if (config == null) return false;

    // Compare lowercase, trimmed answers
    return BCrypt.checkpw(
      answer.trim().toLowerCase(),
      config.securityAnswerHash,
    );
  }

  /// Get security question (for display in recovery flow)
  String? getSecurityQuestion() {
    return _getRecoveryConfig()?.securityQuestion;
  }

  /// Clear recovery config (e.g., when user deletes profile)
  Future<void> clearRecoveryConfig() async {
    await _storage.deleteSetting(SettingsKeys.parentPinRecoveryConfig);
  }
}

/// Exception thrown when PIN verification is attempted during lockout.
class PinLockoutException implements Exception {
  PinLockoutException(this.remainingMinutes);

  final int remainingMinutes;

  @override
  String toString() =>
      'För många felaktiga försök. Försök igen om $remainingMinutes minut${remainingMinutes != 1 ? 'er' : ''}.';
}
