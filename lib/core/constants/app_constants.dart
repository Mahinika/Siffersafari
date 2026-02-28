import '../../domain/constants/learning_constants.dart';
import 'achievement_ids.dart';
import 'storage_constants.dart';
import 'ui_constants.dart';

export 'achievement_ids.dart' show AchievementIds;
export 'storage_constants.dart' show StorageConstants;
export 'ui_constants.dart' show AppColors, UiConstants;

/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Siffersafari';
  static const String appVersion = '1.0.0';

  // Session Configuration
  static const int questionsPerSession = 10;
  static const int timerDurationSeconds = 30;
  static const double targetSuccessRate = 0.75; // 75%

  // Points System
  static const int basePointsPerQuestion = 10;
  static const int bonusPointsForSpeed = 5;
  static const int streakBonusMultiplier = 2;

  // Spaced Repetition Intervals (in days)
  // Forwarded to domain constants to keep learning rules Flutter-free.
  static const int firstReviewInterval = LearningConstants.firstReviewInterval;
  static const int secondReviewInterval =
      LearningConstants.secondReviewInterval;
  static const int thirdReviewInterval = LearningConstants.thirdReviewInterval;

  // Adaptive Difficulty
  // Forwarded to domain constants to keep learning rules Flutter-free.
  static const int questionsBeforeAdjustment =
      LearningConstants.questionsBeforeAdjustment;
  static const double difficultyIncreaseThreshold =
      LearningConstants.difficultyIncreaseThreshold;
  static const double difficultyDecreaseThreshold =
      LearningConstants.difficultyDecreaseThreshold;

  // UI Constants
  static const double defaultPadding = UiConstants.defaultPadding;
  static const double smallPadding = UiConstants.smallPadding;
  static const double largePadding = UiConstants.largePadding;
  static const double borderRadius = UiConstants.borderRadius;
  static const double iconSize = UiConstants.iconSize;
  static const double largeIconSize = UiConstants.largeIconSize;
  static const double minTouchTargetSize = UiConstants.minTouchTargetSize;

  // Animation Durations
  static const Duration microAnimationDuration =
      UiConstants.microAnimationDuration;
  static const Duration shortAnimationDuration =
      UiConstants.shortAnimationDuration;
  static const Duration mediumAnimationDuration =
      UiConstants.mediumAnimationDuration;
  static const Duration longAnimationDuration =
      UiConstants.longAnimationDuration;

  // Component sizing
  static const double answerButtonHeight = UiConstants.answerButtonHeight;
  static const double feedbackDialogIconSize =
      UiConstants.feedbackDialogIconSize;

  // Hive Box Names
  static const String userProgressBox = StorageConstants.userProgressBox;
  static const String quizHistoryBox = StorageConstants.quizHistoryBox;
  static const String settingsBox = StorageConstants.settingsBox;

  // Achievement IDs
  static const String firstQuizAchievement =
      AchievementIds.firstQuizAchievement;
  static const String streak7Achievement = AchievementIds.streak7Achievement;
  static const String streak30Achievement = AchievementIds.streak30Achievement;
  static const String master100Achievement =
      AchievementIds.master100Achievement;
  static const String perfectScoreAchievement =
      AchievementIds.perfectScoreAchievement;
}
