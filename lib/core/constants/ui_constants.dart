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

  // Layout constraints
  static const double contentMaxWidth = 520.0;

  // Micro spacing
  static const double microSpacing2 = 2.0;
  static const double microSpacing4 = 4.0;
  static const double microSpacing6 = 6.0;
  static const double microSpacing8 = 8.0;

  // Progress indicators
  static const double progressBarHeightSmall = 10.0;
  static const double progressBarHeightMedium = 12.0;

  // Animation Durations
  static const Duration microAnimationDuration = Duration(milliseconds: 100);
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Page transitions
  static const Duration pageTransitionSlow = Duration(milliseconds: 300);
  static const Duration pageTransitionNormal = Duration(milliseconds: 250);
  static const Offset pageTransitionSlideBeginOffset = Offset(0.0, 0.03);

  // P1: App-specific UI durations
  static const Duration momentDisplayDuration = Duration(milliseconds: 1600);
  static const Duration celebrationPopDuration = Duration(milliseconds: 650);

  // Background overlay (scrim) used on top of themed background images.
  static const double backgroundOverlayOpacity = 0.72;

  // Component sizing
  static const double answerButtonHeight = 64.0;
  static const double feedbackDialogIconSize = 64.0;

  // Typography
  static const double buttonFontSize = 18.0;

  // Tap targets
  static const double minTouchTargetSizeSmall = 44.0;

  // Elevation (Material)
  static const double answerButtonElevationDefault = 3.0;
  static const double answerButtonElevationSelected = 6.0;

  // Shadows
  static const double questionCardShadowBlur = 10.0;
  static const double questionCardShadowOffsetY = 5.0;

  static const double operationCardShadowPrimaryBlur = 12.0;
  static const double operationCardShadowPrimarySpread = 1.0;
  static const double operationCardShadowPrimaryOffsetY = 6.0;

  static const double operationCardShadowAmbientBlur = 20.0;
  static const double operationCardShadowAmbientOffsetY = 8.0;
}

/// Common opacity tokens used across the UI.
///
/// Keep these semantic (what they are used for) rather than numeric.
class AppOpacities {
  AppOpacities._();

  static const double mutedText = 0.70;
  static const double subtleText = 0.54;
  static const double faintText = 0.38;

  static const double cardBorder = 0.12;
  static const double hudBorder = 0.14;
  static const double panelFill = 0.10;
  static const double hudBorderStrong = 0.18;

  // Borders/dividers
  static const double borderSubtle = 0.15;
  static const double borderMedium = 0.20;
  static const double divider = 0.24;

  // Accent fills
  static const double accentFillSubtle = 0.15;

  // Nearly-opaque surfaces (e.g. dropdown menus over themed backgrounds)
  static const double menuSurface = 0.98;

  // Subtle fills (e.g. soft panels, textfield backgrounds)
  static const double subtleFill = 0.08;

  // Strong highlight for borders/tracks using an arbitrary accent color.
  static const double highlightStrong = 0.35;

  static const double shadowAmbient = 0.10;
  static const double operationCardShadowPrimary = 0.40;
  static const double progressTrack = 0.22;
  static const double progressTrackLight = 0.15;
  static const double progressTrackMedium = 0.20;

  static const double cardShadow = 0.18;

  static const double buttonShadowSelected = 0.50;
  static const double buttonShadowIdle = 0.26;
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
