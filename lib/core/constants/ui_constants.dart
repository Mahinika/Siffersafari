import 'package:flutter/material.dart';

/// UI-related constants (Flutter-dependent).
class UiConstants {
  UiConstants._();

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 48.0;
  static const double minTouchTargetSize = 56.0;

  // Animation Durations
  static const Duration microAnimationDuration = Duration(milliseconds: 100);
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Component sizing
  static const double answerButtonHeight = 64.0;
  static const double feedbackDialogIconSize = 64.0;
}

/// Color palette for themes
class AppColors {
  AppColors._();

  // Space Theme
  static const Color spaceBackground = Color(0xFF122B4A);
  static const Color spacePrimary = Color(0xFFE86F2D);
  static const Color spaceSecondary = Color(0xFFF7B733);
  static const Color spaceAccent = Color(0xFF1FAFA0);

  // Jungle Theme
  static const Color jungleBackground = Color(0xFF1C4A2B);
  static const Color junglePrimary = Color(0xFF2BAE66);
  static const Color jungleSecondary = Color(0xFF7BC96F);
  static const Color jungleAccent = Color(0xFFFFC94A);

  // Common Colors
  static const Color correctAnswer = Color(0xFF22C55E);
  static const Color wrongAnswer = Color(0xFFEF4444);
  static const Color neutralBackground = Color(0xFFFFF6E8);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
}
