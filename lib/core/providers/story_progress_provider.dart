import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/story_progress.dart';
import '../../domain/enums/operation_type.dart';
import '../config/difficulty_config.dart';
import '../services/story_progression_service.dart';
import 'local_storage_repository_provider.dart';
import 'parent_settings_provider.dart';
import 'quest_progression_service_provider.dart';
import 'user_provider.dart';

final storyProgressionServiceProvider =
    Provider<StoryProgressionService>((ref) {
  return const StoryProgressionService();
});

final storyProgressProvider = Provider<StoryProgress?>((ref) {
  final userState = ref.watch(userProvider);
  final user = userState.activeUser;
  final questStatus = userState.questStatus;
  if (user == null || questStatus == null) return null;

  final parentAllowedOps = ref.watch(parentSettingsProvider)[user.userId] ??
      const <OperationType>{
        OperationType.addition,
        OperationType.subtraction,
        OperationType.multiplication,
        OperationType.division,
      };

  final allowedOps = DifficultyConfig.effectiveAllowedOperations(
    parentAllowedOperations: parentAllowedOps,
    gradeLevel: user.gradeLevel,
  );

  final questProgressionService = ref.watch(questProgressionServiceProvider);
  final repository = ref.watch(localStorageRepositoryProvider);
  final storyProgressionService = ref.watch(storyProgressionServiceProvider);

  final path = questProgressionService.questsForUser(
    user,
    allowedOperations: allowedOps,
  );
  final completedQuestIds = repository.getCompletedQuestIds(user.userId);

  return storyProgressionService.build(
    path: path,
    currentStatus: questStatus,
    completedQuestIds: completedQuestIds,
    notice: userState.questNotice,
  );
});
