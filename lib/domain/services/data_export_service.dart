import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/settings_keys.dart';
import '../../data/repositories/local_storage_repository.dart';

/// Service for exporting user data in GDPR-compliant JSON format
class DataExportService {
  final LocalStorageRepository _repository;

  DataExportService({required LocalStorageRepository repository})
      : _repository = repository;

  /// Export all data for a specific user to JSON
  /// Returns path to the generated JSON file
  Future<String> exportUserDataAsJson(String userId) async {
    // Collect all user data
    final userProgress = _repository.getUserProgress(userId);
    if (userProgress == null) {
      throw Exception('User not found: $userId');
    }

    final quizHistory = _repository.getQuizHistory(userId);
    final pinHash = _repository.getSetting(SettingsKeys.parentPinHash);
    final recoveryConfig =
        _repository.getSetting(SettingsKeys.parentPinRecoveryConfig);

    // Build export payload (no sensitive data like PIN hashes)
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
      'userData': {
        'name': userProgress.name,
        'ageGroup': userProgress.ageGroup.name,
        'gradeLevel': userProgress.gradeLevel,
        'totalQuizzesTaken': userProgress.totalQuizzesTaken,
        'totalQuestionsAnswered': userProgress.totalQuestionsAnswered,
        'totalCorrectAnswers': userProgress.totalCorrectAnswers,
        'totalPoints': userProgress.totalPoints,
        'currentStreak': userProgress.currentStreak,
        'longestStreak': userProgress.longestStreak,
      },
      'quizHistory': quizHistory.map((session) {
        // Exclude raw session data, expose high-level stats
        return {
          'sessionId': session['sessionId'],
          'operationType': session['operationType'],
          'difficulty': session['difficulty'],
          'startTime': session['startTime'],
          'endTime': session['endTime'],
          'isComplete': session['isComplete'],
          'successRate': session['successRate'],
          'totalQuestions': session['totalQuestions'],
          'correctAnswers': session['correctAnswers'],
          'points': session['points'],
          'bonusPoints': session['bonusPoints'],
          'pointsWithBonus': session['pointsWithBonus'],
        };
      }).toList(),
      'settings': {
        'pinConfigured': pinHash is String && pinHash.isNotEmpty,
        'recoveryConfigured': recoveryConfig is Map,
      },
      'note': 'This export contains your profile and quiz history. '
          'Sensitive information like PIN hashes and security answers are not included '
          'for security reasons. For PIN recovery, use the recovery flow in the app.',
    };

    // Write to JSON file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'user_data_export_${userId}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');

    final jsonString = jsonEncode(exportData);
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Export metadata only (profile summary without detailed history)
  Future<String> exportUserMetadataAsJson(String userId) async {
    final userProgress = _repository.getUserProgress(userId);
    if (userProgress == null) {
      throw Exception('User not found: $userId');
    }

    final quizCount = _repository.getQuizHistory(userId).length;

    final metadata = {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
      'name': userProgress.name,
      'ageGroup': userProgress.ageGroup.name,
      'gradeLevel': userProgress.gradeLevel,
      'totalQuizzesTaken': userProgress.totalQuizzesTaken,
      'quizHistoryRecordsCount': quizCount,
      'totalCorrectAnswers': userProgress.totalCorrectAnswers,
      'totalPoints': userProgress.totalPoints,
    };

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'user_metadata_${userId}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');

    final jsonString = jsonEncode(metadata);
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// List all previously exported files for a user (for easy access / deletion)
  Future<List<File>> listExportedFiles(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final files = Directory(directory.path)
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              f.path.contains('user_data_export_$userId') ||
              f.path.contains('user_metadata_$userId'),
        )
        .toList();
    return files;
  }

  /// Delete an exported file
  Future<void> deleteExportedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
