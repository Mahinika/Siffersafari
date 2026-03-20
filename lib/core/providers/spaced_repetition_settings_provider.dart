import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../../shared/settings/quiz_feature_settings.dart';
import 'local_storage_repository_provider.dart';

class SpacedRepetitionEnabledNotifier extends StateNotifier<bool> {
  SpacedRepetitionEnabledNotifier(this._repository, this._userId)
      : super(
          QuizFeatureSettings.readSpacedRepetitionEnabled(
            repository: _repository,
            userId: _userId,
          ),
        );

  final LocalStorageRepository _repository;
  final String _userId;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await QuizFeatureSettings.saveSpacedRepetitionEnabled(
      repository: _repository,
      userId: _userId,
      enabled: enabled,
    );
  }
}

final spacedRepetitionEnabledProvider =
    StateNotifierProvider.family<SpacedRepetitionEnabledNotifier, bool, String>(
  (ref, userId) {
    final repository = ref.watch(localStorageRepositoryProvider);
    return SpacedRepetitionEnabledNotifier(repository, userId);
  },
);
