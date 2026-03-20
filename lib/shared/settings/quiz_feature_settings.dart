import 'package:siffersafari/core/config/app_features.dart';
import 'package:siffersafari/core/constants/settings_keys.dart';
import 'package:siffersafari/data/repositories/local_storage_repository.dart';

final class QuizFeatureSettings {
  const QuizFeatureSettings._();

  static bool defaultWordProblemsEnabled({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    try {
      final user = repository.getUserProgress(userId);
      if (user?.gradeLevel == 1) return false;
    } catch (_) {
      return AppFeatures.wordProblemsEnabled;
    }
    return AppFeatures.wordProblemsEnabled;
  }

  static bool hasStoredWordProblemsEnabled({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    try {
      return repository.getSetting(SettingsKeys.wordProblemsEnabled(userId))
          is bool;
    } catch (_) {
      return false;
    }
  }

  static bool readWordProblemsEnabled({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    final fallback = defaultWordProblemsEnabled(
      repository: repository,
      userId: userId,
    );
    try {
      final raw = repository.getSetting(
        SettingsKeys.wordProblemsEnabled(userId),
        defaultValue: fallback,
      );
      return raw is bool ? raw : fallback;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> saveWordProblemsEnabled({
    required LocalStorageRepository repository,
    required String userId,
    required bool enabled,
  }) {
    return repository.saveSetting(
      SettingsKeys.wordProblemsEnabled(userId),
      enabled,
    );
  }

  static bool readMissingNumberEnabled({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    try {
      final raw = repository.getSetting(
        SettingsKeys.missingNumberEnabled(userId),
        defaultValue: AppFeatures.missingNumberEnabled,
      );
      return raw is bool ? raw : AppFeatures.missingNumberEnabled;
    } catch (_) {
      return AppFeatures.missingNumberEnabled;
    }
  }

  static Future<void> saveMissingNumberEnabled({
    required LocalStorageRepository repository,
    required String userId,
    required bool enabled,
  }) {
    return repository.saveSetting(
      SettingsKeys.missingNumberEnabled(userId),
      enabled,
    );
  }

  static bool readSpacedRepetitionEnabled({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    try {
      final raw = repository.getSetting(
        SettingsKeys.spacedRepetitionEnabled(userId),
        defaultValue: AppFeatures.spacedRepetitionEnabled,
      );
      return raw is bool ? raw : AppFeatures.spacedRepetitionEnabled;
    } catch (_) {
      return AppFeatures.spacedRepetitionEnabled;
    }
  }

  static Future<void> saveSpacedRepetitionEnabled({
    required LocalStorageRepository repository,
    required String userId,
    required bool enabled,
  }) {
    return repository.saveSetting(
      SettingsKeys.spacedRepetitionEnabled(userId),
      enabled,
    );
  }
}
