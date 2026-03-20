import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../../shared/settings/quiz_feature_settings.dart';
import 'local_storage_repository_provider.dart';

class WordProblemsEnabledNotifier extends StateNotifier<bool> {
  WordProblemsEnabledNotifier(this._repository, this._userId)
      : super(
          QuizFeatureSettings.readWordProblemsEnabled(
            repository: _repository,
            userId: _userId,
          ),
        );

  final LocalStorageRepository _repository;
  final String _userId;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await QuizFeatureSettings.saveWordProblemsEnabled(
      repository: _repository,
      userId: _userId,
      enabled: enabled,
    );
  }
}

final wordProblemsEnabledProvider =
    StateNotifierProvider.family<WordProblemsEnabledNotifier, bool, String>(
  (ref, userId) {
    final repository = ref.watch(localStorageRepositoryProvider);
    return WordProblemsEnabledNotifier(repository, userId);
  },
);
