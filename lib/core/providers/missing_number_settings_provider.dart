import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../../shared/settings/quiz_feature_settings.dart';
import 'local_storage_repository_provider.dart';

class MissingNumberEnabledNotifier extends StateNotifier<bool> {
  MissingNumberEnabledNotifier(this._repository, this._userId)
      : super(
          QuizFeatureSettings.readMissingNumberEnabled(
            repository: _repository,
            userId: _userId,
          ),
        );

  final LocalStorageRepository _repository;
  final String _userId;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await QuizFeatureSettings.saveMissingNumberEnabled(
      repository: _repository,
      userId: _userId,
      enabled: enabled,
    );
  }
}

final missingNumberEnabledProvider =
    StateNotifierProvider.family<MissingNumberEnabledNotifier, bool, String>(
  (ref, userId) {
    final repository = ref.watch(localStorageRepositoryProvider);
    return MissingNumberEnabledNotifier(repository, userId);
  },
);
