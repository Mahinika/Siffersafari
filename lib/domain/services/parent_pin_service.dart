import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/repositories/local_storage_repository.dart';

/// Service for secure parent PIN management with hashing and rate limiting.
class ParentPinService {
  ParentPinService(this._storage);

  final LocalStorageRepository _storage;

  static const String _pinHashKey = 'parent_pin_hash';
  static const String _failedAttemptsKey = 'pin_failed_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';

  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  /// Hash a PIN using SHA-256 with a simple salt.
  String _hashPin(String pin) {
    const salt = 'siffersafari_pin_salt'; // Simple salt for MVP
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if PIN exists (has been set).
  bool hasPinSet() {
    final hash = _storage.getSetting(_pinHashKey) as String?;
    return hash != null && hash.isNotEmpty;
  }

  /// Save a new PIN (hashed).
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.saveSetting(_pinHashKey, hash);
    // Reset failed attempts when setting new PIN
    await _storage.saveSetting(_failedAttemptsKey, 0);
    await _storage.deleteSetting(_lockoutUntilKey);
  }

  /// Verify if provided PIN matches stored hash.
  /// Returns true if correct, false if wrong or locked out.
  /// Throws [PinLockoutException] if currently locked out.
  Future<bool> verifyPin(String pin) async {
    // Check lockout
    final lockoutUntil = _storage.getSetting(_lockoutUntilKey) as int?;
    if (lockoutUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < lockoutUntil) {
        final remainingMinutes = ((lockoutUntil - now) / 1000 / 60).ceil();
        throw PinLockoutException(remainingMinutes);
      } else {
        // Lockout expired, clear it
        await _storage.deleteSetting(_lockoutUntilKey);
        await _storage.saveSetting(_failedAttemptsKey, 0);
      }
    }

    final storedHash = _storage.getSetting(_pinHashKey) as String?;
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    final inputHash = _hashPin(pin);
    final isCorrect = inputHash == storedHash;

    if (isCorrect) {
      // Reset failed attempts on successful login
      await _storage.saveSetting(_failedAttemptsKey, 0);
      await _storage.deleteSetting(_lockoutUntilKey);
      return true;
    } else {
      // Increment failed attempts
      final failedAttempts =
          (_storage.getSetting(_failedAttemptsKey) as int? ?? 0) + 1;
      await _storage.saveSetting(_failedAttemptsKey, failedAttempts);

      if (failedAttempts >= _maxFailedAttempts) {
        // Lock out
        final lockoutUntil =
            DateTime.now().add(_lockoutDuration).millisecondsSinceEpoch;
        await _storage.saveSetting(_lockoutUntilKey, lockoutUntil);
        throw PinLockoutException(_lockoutDuration.inMinutes);
      }

      return false;
    }
  }

  /// Get remaining failed attempts before lockout.
  int getRemainingAttempts() {
    final failedAttempts = _storage.getSetting(_failedAttemptsKey) as int? ?? 0;
    final remaining = _maxFailedAttempts - failedAttempts;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if currently locked out and return remaining minutes.
  int? getLockoutRemainingMinutes() {
    final lockoutUntil = _storage.getSetting(_lockoutUntilKey) as int?;
    if (lockoutUntil == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= lockoutUntil) return null;

    return ((lockoutUntil - now) / 1000 / 60).ceil();
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
