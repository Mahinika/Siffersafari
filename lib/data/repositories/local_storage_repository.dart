import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_progress.dart';

/// Repository for local storage operations using Hive
class LocalStorageRepository {
  Box<dynamic> get _userProgressBox => Hive.box(AppConstants.userProgressBox);
  Box<dynamic> get _quizHistoryBox => Hive.box(AppConstants.quizHistoryBox);
  Box<dynamic> get _settingsBox => Hive.box(AppConstants.settingsBox);

  Map<String, dynamic>? _tryAsStringKeyedMap(dynamic value) {
    if (value is! Map) return null;
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }

  DateTime _sessionStartTime(Map<String, dynamic> session) {
    return DateTime.tryParse(session['startTime']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    await _userProgressBox.put(progress.userId, progress);
  }

  /// Get user progress by ID
  UserProgress? getUserProgress(String userId) {
    return _userProgressBox.get(userId) as UserProgress?;
  }

  /// Get all user profiles
  List<UserProgress> getAllUserProfiles() {
    return _userProgressBox.values.cast<UserProgress>().toList();
  }

  /// Delete user progress
  Future<void> deleteUserProgress(String userId) async {
    await _userProgressBox.delete(userId);
  }

  /// Save a quiz session to history
  Future<void> saveQuizSession(Map<String, dynamic> session) async {
    final sessionId = session['sessionId'] as String;
    await _quizHistoryBox.put(sessionId, session);
  }

  /// Get quiz history for a user
  List<Map<String, dynamic>> getQuizHistory(String userId, {int? limit}) {
    if (limit != null && limit <= 0) return const [];

    // Fast path: when limit is small (typical UI use), avoid sorting the full
    // history. Keep only the newest [limit] items while iterating.
    if (limit != null) {
      final top = <Map<String, dynamic>>[]; // newest -> oldest

      for (final value in _quizHistoryBox.values) {
        final session = _tryAsStringKeyedMap(value);
        if (session == null) continue;
        if (session['userId'] != userId) continue;

        final date = _sessionStartTime(session);

        var insertAt = top.length;
        for (var i = 0; i < top.length; i++) {
          final existingDate = _sessionStartTime(top[i]);
          if (date.isAfter(existingDate)) {
            insertAt = i;
            break;
          }
        }

        if (insertAt == top.length) {
          if (top.length < limit) {
            top.add(session);
          }
        } else {
          top.insert(insertAt, session);
          if (top.length > limit) {
            top.removeLast();
          }
        }
      }

      return top;
    }

    // Full list requested.
    final allSessions = <Map<String, dynamic>>[];
    for (final value in _quizHistoryBox.values) {
      final session = _tryAsStringKeyedMap(value);
      if (session == null) continue;
      if (session['userId'] != userId) continue;
      allSessions.add(session);
    }

    // Sort by date (newest first)
    allSessions.sort((a, b) {
      return _sessionStartTime(b).compareTo(_sessionStartTime(a));
    });

    return allSessions;
  }

  /// Delete quiz history for a user
  Future<void> deleteQuizHistoryForUser(String userId) async {
    final keys = _quizHistoryBox.keys.toList(growable: false);
    for (final key in keys) {
      final value = _quizHistoryBox.get(key);
      if (value is Map && value['userId'] == userId) {
        await _quizHistoryBox.delete(key);
      }
    }
  }

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  /// Get a setting
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await _userProgressBox.clear();
    await _quizHistoryBox.clear();
    await _settingsBox.clear();
  }
}
