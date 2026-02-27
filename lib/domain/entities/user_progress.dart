import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../enums/age_group.dart';
import '../enums/app_theme.dart';
import '../enums/difficulty_level.dart';
import '../enums/mastery_level.dart';
import '../enums/operation_type.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 0)
class UserProgress extends Equatable {
  const UserProgress({
    required this.userId,
    required this.name,
    required this.ageGroup,
    this.gradeLevel,
    this.totalQuizzesTaken = 0,
    this.totalQuestionsAnswered = 0,
    this.totalCorrectAnswers = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPoints = 0,
    this.selectedTheme = AppTheme.space,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.timerEnabled = false,
    this.lastSessionDate,
    this.unlockedThemes = const [AppTheme.space],
    this.achievements = const [],
    this.masteryLevels = const {},
  });

  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final AgeGroup ageGroup;

  /// Selected Swedish grade/year (Åk), 1-9. When set, the app derives
  /// difficulty progression from this value.
  @HiveField(17)
  final int? gradeLevel;

  @HiveField(3)
  final int totalQuizzesTaken;

  @HiveField(4)
  final int totalQuestionsAnswered;

  @HiveField(5)
  final int totalCorrectAnswers;

  @HiveField(6)
  final int currentStreak;

  @HiveField(7)
  final int longestStreak;

  @HiveField(8)
  final int totalPoints;

  @HiveField(9)
  final AppTheme selectedTheme;

  @HiveField(10)
  final bool soundEnabled;

  @HiveField(11)
  final bool musicEnabled;

  @HiveField(12)
  final bool timerEnabled;

  @HiveField(13)
  final DateTime? lastSessionDate;

  @HiveField(14)
  final List<AppTheme> unlockedThemes;

  @HiveField(15)
  final List<String> achievements;

  @HiveField(16)
  final Map<String, double>
      masteryLevels; // Key: "operation_difficulty", Value: success rate

  static const int pointsPerLevel = 200;

  static const List<String> levelTitles = [
    'Rymdnybörjare',
    'Stjärnspanare',
    'Raketräknare',
    'Planetproffs',
    'Kometsnabb',
    'Galaxigeni',
    'Superastronaut',
    'Nebulamästare',
    'Kosmisk hjälte',
    'Legend i rymden',
  ];

  int get level => (totalPoints ~/ pointsPerLevel) + 1;

  String get levelTitle {
    final index = (level - 1).clamp(0, levelTitles.length - 1);
    return levelTitles[index];
  }

  int get pointsIntoLevel => totalPoints % pointsPerLevel;

  int get pointsToNextLevel => pointsPerLevel - pointsIntoLevel;

  double get levelProgress {
    if (pointsPerLevel <= 0) return 0.0;
    return pointsIntoLevel / pointsPerLevel;
  }

  /// Calculate overall success rate
  double get successRate {
    if (totalQuestionsAnswered == 0) return 0.0;
    return totalCorrectAnswers / totalQuestionsAnswered;
  }

  /// Get mastery level for a specific operation and difficulty
  MasteryLevel getMasteryLevel(
    OperationType operation,
    DifficultyLevel difficulty,
  ) {
    final key = '${operation.name}_${difficulty.name}';
    final rate = masteryLevels[key] ?? 0.0;

    if (rate >= MasteryLevel.advanced.threshold) return MasteryLevel.advanced;
    if (rate >= MasteryLevel.proficient.threshold) {
      return MasteryLevel.proficient;
    }
    if (rate >= MasteryLevel.developing.threshold) {
      return MasteryLevel.developing;
    }
    return MasteryLevel.notStarted;
  }

  UserProgress copyWith({
    String? userId,
    String? name,
    AgeGroup? ageGroup,
    int? gradeLevel,
    int? totalQuizzesTaken,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
    int? currentStreak,
    int? longestStreak,
    int? totalPoints,
    AppTheme? selectedTheme,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? timerEnabled,
    DateTime? lastSessionDate,
    List<AppTheme>? unlockedThemes,
    List<String>? achievements,
    Map<String, double>? masteryLevels,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      achievements: achievements ?? this.achievements,
      masteryLevels: masteryLevels ?? this.masteryLevels,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        ageGroup,
        gradeLevel,
        totalQuizzesTaken,
        totalQuestionsAnswered,
        totalCorrectAnswers,
        currentStreak,
        longestStreak,
        totalPoints,
        selectedTheme,
        soundEnabled,
        musicEnabled,
        timerEnabled,
        lastSessionDate,
        unlockedThemes,
        achievements,
        masteryLevels,
      ];
}
