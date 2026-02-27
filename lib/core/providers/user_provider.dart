import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/daily_goal_utils.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/age_group.dart';

class UserState {
  const UserState({
    this.activeUser,
    this.allUsers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastReward,
    this.dailyGoalTarget = defaultDailyGoalTarget,
    this.dailyGoalProgressToday = 0,
  });

  final UserProgress? activeUser;
  final List<UserProgress> allUsers;
  final bool isLoading;
  final String? errorMessage;
  final AchievementReward? lastReward;
  final int dailyGoalTarget;
  final int dailyGoalProgressToday;

  UserState copyWith({
    UserProgress? activeUser,
    List<UserProgress>? allUsers,
    bool? isLoading,
    String? errorMessage,
    AchievementReward? lastReward,
    int? dailyGoalTarget,
    int? dailyGoalProgressToday,
  }) {
    return UserState(
      activeUser: activeUser ?? this.activeUser,
      allUsers: allUsers ?? this.allUsers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastReward: lastReward,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyGoalProgressToday:
          dailyGoalProgressToday ?? this.dailyGoalProgressToday,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this._repository, this._achievementService, this._audioService)
      : super(const UserState());

  static const String _activeUserIdKey = 'active_user_id';
  static const String _legacyDemoUserName = 'Demo Användare';
  static String _onboardingDoneKey(String userId) => 'onboarding_done_$userId';
  static String _allowedOpsKey(String userId) => 'allowed_ops_$userId';

  int _readDailyGoalTarget(String userId) {
    final raw = _repository.getSetting(
      dailyGoalTargetKey(userId),
      defaultValue: defaultDailyGoalTarget,
    );
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return defaultDailyGoalTarget;
  }

  int _readDailyGoalProgressToday(String userId, DateTime now) {
    final raw = _repository.getSetting(
      dailyGoalProgressKey(userId, now),
      defaultValue: 0,
    );
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  final LocalStorageRepository _repository;
  final AchievementService _achievementService;
  final AudioService _audioService;

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

    final activeUser = storedActiveUser ??
        (state.activeUser != null && !_isLegacyDemoUser(state.activeUser!)
            ? state.activeUser
            : null) ??
        (users.isNotEmpty ? users.first : null);

    final now = DateTime.now();
    final dailyGoalTarget =
        activeUser != null ? _readDailyGoalTarget(activeUser.userId) : 0;
    final dailyGoalProgressToday = activeUser != null
        ? _readDailyGoalProgressToday(activeUser.userId, now)
        : 0;

    if (activeUser != null) {
      _syncAudioSettings(activeUser);
    }

    state = state.copyWith(
      allUsers: users,
      activeUser: activeUser,
      dailyGoalTarget:
          dailyGoalTarget > 0 ? dailyGoalTarget : defaultDailyGoalTarget,
      dailyGoalProgressToday: dailyGoalProgressToday,
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
    await _repository.saveSetting(_activeUserIdKey, userId);
    state = state.copyWith(activeUser: user);
  }

  Future<void> createUser({
    required String userId,
    required String name,
    required AgeGroup ageGroup,
    int? gradeLevel,
  }) async {
    final newUser = UserProgress(
      userId: userId,
      name: name,
      ageGroup: ageGroup,
      gradeLevel: gradeLevel,
    );

    await _repository.saveUserProgress(newUser);
    await _repository.saveSetting(_activeUserIdKey, userId);
    await loadUsers();
    _syncAudioSettings(newUser);
    state = state.copyWith(activeUser: newUser);
  }

  Future<void> saveUser(UserProgress user) async {
    await _repository.saveUserProgress(user);
    await _repository.saveSetting(_activeUserIdKey, user.userId);
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

    // Update "daily goal" progress (questions answered today).
    final progressKey = dailyGoalProgressKey(user.userId, now);
    final currentProgress = _readDailyGoalProgressToday(user.userId, now);
    await _repository.saveSetting(
      progressKey,
      currentProgress + session.totalQuestions,
    );
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
  return UserNotifier(repository, achievementService, audioService);
});
