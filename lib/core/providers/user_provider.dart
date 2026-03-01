import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/di/injection.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/quest_progression_service.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/quest.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/operation_type.dart';

class UserState {
  const UserState({
    this.activeUser,
    this.allUsers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastReward,
    this.questStatus,
    this.questNotice,
  });

  final UserProgress? activeUser;
  final List<UserProgress> allUsers;
  final bool isLoading;
  final String? errorMessage;
  final AchievementReward? lastReward;
  final QuestStatus? questStatus;
  final String? questNotice;

  static const Object _unset = Object();

  UserState copyWith({
    UserProgress? activeUser,
    List<UserProgress>? allUsers,
    bool? isLoading,
    String? errorMessage,
    AchievementReward? lastReward,
    QuestStatus? questStatus,
    Object? questNotice = _unset,
  }) {
    return UserState(
      activeUser: activeUser ?? this.activeUser,
      allUsers: allUsers ?? this.allUsers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastReward: lastReward,
      questStatus: questStatus ?? this.questStatus,
      questNotice:
          questNotice == _unset ? this.questNotice : questNotice as String?,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(
    this._repository,
    this._achievementService,
    this._audioService,
    this._questProgressionService,
  ) : super(const UserState());

  static const String _activeUserIdKey = 'active_user_id';
  static const String _legacyDemoUserName = 'Demo Användare';
  static String _onboardingDoneKey(String userId) => 'onboarding_done_$userId';
  static String _allowedOpsKey(String userId) => 'allowed_ops_$userId';
  static String _questCurrentKey(String userId) => 'quest_current_$userId';
  static String _questCompletedKey(String userId) => 'quest_completed_$userId';

  final LocalStorageRepository _repository;
  final AchievementService _achievementService;
  final AudioService _audioService;
  final QuestProgressionService _questProgressionService;

  static const _baseOperations = <OperationType>{
    OperationType.addition,
    OperationType.subtraction,
    OperationType.multiplication,
    OperationType.division,
  };

  Set<OperationType> _readParentAllowedOperations(String userId) {
    final raw = _repository.getSetting(_allowedOpsKey(userId));
    if (raw is List) {
      final ops = raw
          .whereType<String>()
          .map(_operationFromName)
          .whereType<OperationType>()
          .where(_baseOperations.contains)
          .toSet();

      if (ops.isNotEmpty) return ops;
    }

    return {..._baseOperations};
  }

  OperationType? _operationFromName(String name) {
    for (final op in OperationType.values) {
      if (op.name == name) return op;
    }
    return null;
  }

  Set<OperationType> _effectiveAllowedOperationsFor(UserProgress user) {
    final parentAllowed = _readParentAllowedOperations(user.userId);
    return DifficultyConfig.effectiveAllowedOperations(
      parentAllowedOperations: parentAllowed,
      gradeLevel: user.gradeLevel,
    );
  }

  Set<String> _readCompletedQuestIds(String userId) {
    final raw = _repository.getSetting(_questCompletedKey(userId));
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  String? _readCurrentQuestId(String userId) {
    final raw = _repository.getSetting(_questCurrentKey(userId));
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  Future<void> _ensureQuestInitialized(UserProgress user) async {
    final current = _readCurrentQuestId(user.userId);
    if (current != null) return;

    final allowedOps = _effectiveAllowedOperationsFor(user);
    await _repository.saveSetting(
      _questCurrentKey(user.userId),
      _questProgressionService.firstQuestId(
        user,
        allowedOperations: allowedOps,
      ),
    );
    await _repository.saveSetting(_questCompletedKey(user.userId), <String>[]);
  }

  Future<void> _setQuestState({
    required String userId,
    required String currentQuestId,
    required Set<String> completedQuestIds,
  }) async {
    await _repository.saveSetting(_questCurrentKey(userId), currentQuestId);
    await _repository.saveSetting(
      _questCompletedKey(userId),
      completedQuestIds.toList(growable: false),
    );
  }

  /// Ensures the persisted quest pointer is valid for the user's current
  /// quest path (grade/age-group) and not already completed.
  Future<void> _reconcileQuestPointer(UserProgress user) async {
    await _ensureQuestInitialized(user);

    final completed = _readCompletedQuestIds(user.userId);
    final current = _readCurrentQuestId(user.userId);

    final allowedOps = _effectiveAllowedOperationsFor(user);
    final status = _questProgressionService.getCurrentStatus(
      user: user,
      currentQuestId: current,
      completedQuestIds: completed,
      allowedOperations: allowedOps,
    );

    if (current != status.quest.id) {
      await _repository.saveSetting(
        _questCurrentKey(user.userId),
        status.quest.id,
      );
      final label = user.gradeLevel != null
          ? 'Årskurs ${user.gradeLevel}'
          : user.ageGroup.displayName;
      state = state.copyWith(
        questNotice: 'Uppdrag anpassat till $label.',
      );
    }
  }

  void clearQuestNotice() {
    if (state.questNotice == null) return;
    state = state.copyWith(questNotice: null);
  }

  void _syncAudioSettings(UserProgress user) {
    _audioService.setSoundEnabled(user.soundEnabled);
    _audioService.setMusicEnabled(user.musicEnabled);
  }

  bool _isLegacyDemoUser(UserProgress user) {
    final normalized = user.name.trim().toLowerCase();
    final legacyNormalized = _legacyDemoUserName.toLowerCase();
    return normalized == legacyNormalized ||
        normalized.replaceAll(' ', '') == legacyNormalized.replaceAll(' ', '');
  }

  Future<void> _cleanupLegacyDemoUserIfNeeded() async {
    final users = _repository.getAllUserProfiles();
    final demoUsers = users.where(_isLegacyDemoUser).toList();
    if (demoUsers.isEmpty) return;

    final storedActiveUserId = _repository.getSetting(_activeUserIdKey);
    final demoUserIds = demoUsers.map((u) => u.userId).toSet();

    for (final demo in demoUsers) {
      await _repository.deleteQuizHistoryForUser(demo.userId);
      await _repository.deleteSetting(_onboardingDoneKey(demo.userId));
      await _repository.deleteSetting(_allowedOpsKey(demo.userId));
      await _repository.deleteUserProgress(demo.userId);
    }

    if (storedActiveUserId is String &&
        demoUserIds.contains(storedActiveUserId)) {
      await _repository.deleteSetting(_activeUserIdKey);
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await _cleanupLegacyDemoUserIfNeeded();

    final users = _repository
        .getAllUserProfiles()
        .where((u) => !_isLegacyDemoUser(u))
        .toList();

    final storedActiveUserId = _repository.getSetting(_activeUserIdKey);
    final storedActiveUser = storedActiveUserId is String
        ? users.cast<UserProgress?>().firstWhere(
              (u) => u?.userId == storedActiveUserId,
              orElse: () => null,
            )
        : null;

    final activeUser =
        storedActiveUser ?? (users.length == 1 ? users.first : null);

    if (activeUser != null) {
      _syncAudioSettings(activeUser);
      await _reconcileQuestPointer(activeUser);
    }

    final questStatus = activeUser == null
        ? null
        : _questProgressionService.getCurrentStatus(
            user: activeUser,
            currentQuestId: _readCurrentQuestId(activeUser.userId),
            completedQuestIds: _readCompletedQuestIds(activeUser.userId),
            allowedOperations: _effectiveAllowedOperationsFor(activeUser),
          );

    state = state.copyWith(
      allUsers: users,
      activeUser: activeUser,
      questStatus: questStatus,
      isLoading: false,
    );
  }

  Future<void> selectUser(String userId) async {
    UserProgress? user;
    for (final u in state.allUsers) {
      if (u.userId == userId) {
        user = u;
        break;
      }
    }

    user ??= _repository.getUserProgress(userId);
    if (user == null) return;

    _syncAudioSettings(user);
    await _reconcileQuestPointer(user);

    final allowedOps = _effectiveAllowedOperationsFor(user);
    final questStatus = _questProgressionService.getCurrentStatus(
      user: user,
      currentQuestId: _readCurrentQuestId(user.userId),
      completedQuestIds: _readCompletedQuestIds(user.userId),
      allowedOperations: allowedOps,
    );
    await _repository.saveSetting(_activeUserIdKey, userId);
    state = state.copyWith(activeUser: user, questStatus: questStatus);
  }

  Future<void> createUser({
    required String userId,
    required String name,
    required AgeGroup ageGroup,
    String avatarEmoji = '🧒',
    int? gradeLevel,
  }) async {
    final newUser = UserProgress(
      userId: userId,
      name: name,
      ageGroup: ageGroup,
      avatarEmoji: avatarEmoji,
      gradeLevel: gradeLevel,
    );

    await _repository.saveUserProgress(newUser);
    await _repository.saveSetting(_activeUserIdKey, userId);
    await _reconcileQuestPointer(newUser);
    await loadUsers();
    _syncAudioSettings(newUser);
    state = state.copyWith(activeUser: newUser);
  }

  Future<void> saveUser(UserProgress user) async {
    await _repository.saveUserProgress(user);
    await _repository.saveSetting(_activeUserIdKey, user.userId);
    await _reconcileQuestPointer(user);
    await loadUsers();
    _syncAudioSettings(user);
    state = state.copyWith(activeUser: user);
  }

  Future<void> applyQuizResult(QuizSession session) async {
    final user = state.activeUser;
    if (user == null) {
      return;
    }

    final now = DateTime.now();

    final updatedStreak = _calculateStreak(
      currentStreak: user.currentStreak,
      lastSessionDate: user.lastSessionDate,
      now: now,
    );

    final updatedLongestStreak =
        updatedStreak > user.longestStreak ? updatedStreak : user.longestStreak;

    final updatedMastery = _updateMastery(
      current: user.masteryLevels,
      session: session,
    );

    final reward = _achievementService.evaluate(
      user: user.copyWith(
        currentStreak: updatedStreak,
      ),
      session: session,
    );

    final updatedAchievements = [
      ...user.achievements,
      ...reward.unlockedIds.where((id) => !user.achievements.contains(id)),
    ];

    final updatedSteps = {
      ...user.operationDifficultySteps,
      ...session.difficultyStepsByOperation.map(
        (k, v) => MapEntry(k.name, v),
      ),
    };

    final updatedUser = user.copyWith(
      totalQuizzesTaken: user.totalQuizzesTaken + 1,
      totalQuestionsAnswered:
          user.totalQuestionsAnswered + session.totalQuestions,
      totalCorrectAnswers: user.totalCorrectAnswers + session.correctAnswers,
      currentStreak: updatedStreak,
      longestStreak: updatedLongestStreak,
      totalPoints: user.totalPoints + session.totalPoints + reward.bonusPoints,
      lastSessionDate: now,
      masteryLevels: updatedMastery,
      achievements: updatedAchievements,
      operationDifficultySteps: updatedSteps,
    );

    await _reconcileQuestPointer(user);
    final completedQuestIds = _readCompletedQuestIds(user.userId);
    final currentQuestId = _readCurrentQuestId(user.userId) ??
        _questProgressionService.firstQuestId(
          user,
          allowedOperations: _effectiveAllowedOperationsFor(user),
        );

    final allowedOps = _effectiveAllowedOperationsFor(updatedUser);

    final beforeQuestStatus = _questProgressionService.getCurrentStatus(
      user: updatedUser,
      currentQuestId: currentQuestId,
      completedQuestIds: completedQuestIds,
      allowedOperations: allowedOps,
    );

    // If current quest is completed, mark it done and advance.
    if (beforeQuestStatus.isCompleted &&
        !completedQuestIds.contains(beforeQuestStatus.quest.id)) {
      final updatedCompleted = {
        ...completedQuestIds,
        beforeQuestStatus.quest.id,
      };
      final nextId = _questProgressionService.nextQuestId(
        user: updatedUser,
        currentQuestId: beforeQuestStatus.quest.id,
        allowedOperations: allowedOps,
      );
      await _setQuestState(
        userId: user.userId,
        currentQuestId: nextId ?? beforeQuestStatus.quest.id,
        completedQuestIds: updatedCompleted,
      );
    }

    // If grade/age-group changed earlier, ensure the quest pointer still
    // matches the user's current path.
    await _reconcileQuestPointer(updatedUser);

    final questStatus = _questProgressionService.getCurrentStatus(
      user: updatedUser,
      currentQuestId: _readCurrentQuestId(user.userId),
      completedQuestIds: _readCompletedQuestIds(user.userId),
      allowedOperations: allowedOps,
    );

    // Save a lightweight quiz history record (for parent/teacher dashboard).
    await _repository.saveQuizSession({
      'sessionId': session.sessionId,
      'userId': user.userId,
      'operationType': session.operationType.name,
      'difficulty': session.difficulty.name,
      'correctAnswers': session.correctAnswers,
      'totalQuestions': session.totalQuestions,
      'successRate': session.successRate,
      'points': session.totalPoints,
      'bonusPoints': reward.bonusPoints,
      'pointsWithBonus': session.totalPoints + reward.bonusPoints,
      'startTime': (session.startTime ?? now).toIso8601String(),
      'endTime': (session.endTime ?? now).toIso8601String(),
    });

    await _repository.saveUserProgress(updatedUser);
    await loadUsers();
    _syncAudioSettings(updatedUser);
    state = state.copyWith(
      activeUser: updatedUser,
      lastReward: reward,
      questStatus: questStatus,
    );
  }

  int _calculateStreak({
    required int currentStreak,
    required DateTime? lastSessionDate,
    required DateTime now,
  }) {
    if (lastSessionDate == null) return 1;

    final lastDate = DateTime(
      lastSessionDate.year,
      lastSessionDate.month,
      lastSessionDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    final difference = today.difference(lastDate).inDays;

    if (difference == 0) return currentStreak; // Same day
    if (difference == 1) return currentStreak + 1;
    return 1;
  }

  Map<String, double> _updateMastery({
    required Map<String, double> current,
    required QuizSession session,
  }) {
    final key = '${session.operationType.name}_${session.difficulty.name}';
    final previousRate = current[key] ?? 0.0;
    final newRate = session.successRate;
    final updatedRate =
        previousRate == 0.0 ? newRate : (previousRate + newRate) / 2;

    return {
      ...current,
      key: updatedRate,
    };
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repository = getIt<LocalStorageRepository>();
  final achievementService = getIt<AchievementService>();
  final audioService = getIt<AudioService>();
  final questProgressionService = getIt<QuestProgressionService>();
  return UserNotifier(
    repository,
    achievementService,
    audioService,
    questProgressionService,
  );
});
