import 'dart:ui' show Offset;

import '../../domain/constants/learning_constants.dart';
import 'achievement_ids.dart';
import 'storage_constants.dart';
import 'ui_constants.dart';

export 'achievement_ids.dart' show AchievementIds;
export 'storage_constants.dart' show StorageConstants;
export 'ui_constants.dart' show AppColors, AppOpacities, UiConstants;

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

    static const double contentMaxWidth = UiConstants.contentMaxWidth;

  static const double microSpacing2 = UiConstants.microSpacing2;
  static const double microSpacing4 = UiConstants.microSpacing4;
  static const double microSpacing6 = UiConstants.microSpacing6;
  static const double microSpacing8 = UiConstants.microSpacing8;

  static const double progressBarHeightSmall =
      UiConstants.progressBarHeightSmall;
  static const double progressBarHeightMedium =
      UiConstants.progressBarHeightMedium;

    static const double backgroundOverlayOpacity =
            UiConstants.backgroundOverlayOpacity;

  // Animation Durations
  static const Duration microAnimationDuration =
      UiConstants.microAnimationDuration;
  static const Duration shortAnimationDuration =
      UiConstants.shortAnimationDuration;
  static const Duration mediumAnimationDuration =
      UiConstants.mediumAnimationDuration;
  static const Duration longAnimationDuration =
      UiConstants.longAnimationDuration;

  static const Duration pageTransitionSlow = UiConstants.pageTransitionSlow;
  static const Duration pageTransitionNormal = UiConstants.pageTransitionNormal;
    static const Offset pageTransitionSlideBeginOffset =
            UiConstants.pageTransitionSlideBeginOffset;

  static const Duration momentDisplayDuration =
      UiConstants.momentDisplayDuration;
  static const Duration celebrationPopDuration =
      UiConstants.celebrationPopDuration;

  // Component sizing
  static const double answerButtonHeight = UiConstants.answerButtonHeight;
  static const double feedbackDialogIconSize =
      UiConstants.feedbackDialogIconSize;

  static const double buttonFontSize = UiConstants.buttonFontSize;
  static const double minTouchTargetSizeSmall =
      UiConstants.minTouchTargetSizeSmall;

  // Elevation
  static const double answerButtonElevationDefault =
      UiConstants.answerButtonElevationDefault;
  static const double answerButtonElevationSelected =
      UiConstants.answerButtonElevationSelected;

  // Shadows
  static const double questionCardShadowBlur = UiConstants.questionCardShadowBlur;
  static const double questionCardShadowOffsetY =
      UiConstants.questionCardShadowOffsetY;

  static const double operationCardShadowPrimaryBlur =
      UiConstants.operationCardShadowPrimaryBlur;
  static const double operationCardShadowPrimarySpread =
      UiConstants.operationCardShadowPrimarySpread;
  static const double operationCardShadowPrimaryOffsetY =
      UiConstants.operationCardShadowPrimaryOffsetY;

  static const double operationCardShadowAmbientBlur =
      UiConstants.operationCardShadowAmbientBlur;
  static const double operationCardShadowAmbientOffsetY =
      UiConstants.operationCardShadowAmbientOffsetY;

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
