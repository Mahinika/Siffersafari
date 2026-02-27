import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Math Game App';
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
  static const int firstReviewInterval = 2;
  static const int secondReviewInterval = 7;
  static const int thirdReviewInterval = 14;

  // Adaptive Difficulty
  static const int questionsBeforeAdjustment = 5;
  static const double difficultyIncreaseThreshold = 0.85;
  static const double difficultyDecreaseThreshold = 0.60;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 48.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Hive Box Names
  static const String userProgressBox = 'user_progress';
  static const String quizHistoryBox = 'quiz_history';
  static const String settingsBox = 'settings';

  // Achievement IDs
  static const String firstQuizAchievement = 'first_quiz';
  static const String streak7Achievement = 'streak_7';
  static const String streak30Achievement = 'streak_30';
  static const String master100Achievement = 'master_100';
  static const String perfectScoreAchievement = 'perfect_score';
}

/// Color palette for themes
class AppColors {
  AppColors._();

  // Space Theme
  static const Color spaceBackground = Color(0xFF0A0E27);
  static const Color spacePrimary = Color(0xFF6366F1);
  static const Color spaceSecondary = Color(0xFF8B5CF6);
  static const Color spaceAccent = Color(0xFFF59E0B);

  // Jungle Theme
  static const Color jungleBackground = Color(0xFF1A3A1A);
  static const Color junglePrimary = Color(0xFF10B981);
  static const Color jungleSecondary = Color(0xFF059669);
  static const Color jungleAccent = Color(0xFFFBBF24);

  // Common Colors
  static const Color correctAnswer = Color(0xFF22C55E);
  static const Color wrongAnswer = Color(0xFFEF4444);
  static const Color neutralBackground = Color(0xFFF3F4F6);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
}
