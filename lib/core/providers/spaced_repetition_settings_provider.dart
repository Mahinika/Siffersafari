import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../config/app_features.dart';
import '../constants/settings_keys.dart';
import 'local_storage_repository_provider.dart';

class SpacedRepetitionEnabledNotifier extends StateNotifier<bool> {
  SpacedRepetitionEnabledNotifier(this._repository, this._userId)
      : super(_readInitialValue(repository: _repository, userId: _userId));

  final LocalStorageRepository _repository;
  final String _userId;

  static bool _readInitialValue({
    required LocalStorageRepository repository,
    required String userId,
  }) {
    final raw = repository.getSetting(
      SettingsKeys.spacedRepetitionEnabled(userId),
      defaultValue: AppFeatures.spacedRepetitionEnabled,
    );
    return raw is bool ? raw : AppFeatures.spacedRepetitionEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _repository.saveSetting(SettingsKeys.spacedRepetitionEnabled(_userId), enabled);
  }
}

final spacedRepetitionEnabledProvider =
    StateNotifierProvider.family<SpacedRepetitionEnabledNotifier, bool, String>(
  (ref, userId) {
    final repository = ref.watch(localStorageRepositoryProvider);
    return SpacedRepetitionEnabledNotifier(repository, userId);
  },
);
