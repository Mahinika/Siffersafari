import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../config/app_features.dart';
import '../di/injection.dart';

String wordProblemsEnabledKey(String userId) => 'word_problems_enabled_$userId';

class WordProblemsEnabledNotifier extends StateNotifier<bool> {
  WordProblemsEnabledNotifier(this._repository, this._userId)
      : super(_readInitialValue(repository: _repository, userId: _userId));

  final LocalStorageRepository _repository;
  final String _userId;

  static bool _readInitialValue({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    final raw = repository.getSetting(
      wordProblemsEnabledKey(userId),
      defaultValue: AppFeatures.wordProblemsEnabled,
    );
    return raw is bool ? raw : AppFeatures.wordProblemsEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _repository.saveSetting(wordProblemsEnabledKey(_userId), enabled);
  }
}

final wordProblemsEnabledProvider =
    StateNotifierProvider.family<WordProblemsEnabledNotifier, bool, String>(
  (ref, userId) {
    final repository = getIt<LocalStorageRepository>();
    return WordProblemsEnabledNotifier(repository, userId);
  },
);
