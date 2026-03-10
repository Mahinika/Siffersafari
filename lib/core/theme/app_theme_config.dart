import 'package:flutter/material.dart';

import '../../domain/enums/app_theme.dart';
import '../constants/app_constants.dart';

/// Character animation states for flexible Ville animation control
enum CharacterAnimationState {
  /// Default idle/resting state
  idle,
  /// Happy/pleased state
  happy,
  /// Celebration/victory state
  celebrate,
  /// Error/confused state
  error,
}

class AppThemeConfig {
  const AppThemeConfig({
    required this.theme,
    required this.backgroundAsset,
    required this.questHeroAsset,
    required this.characterAsset,
    required this.characterLottieAsset,
    this.characterRiveAsset,
    this.characterRiveStateMachine,
    this.preferRiveCharacter = true,
    this.characterIdleAsset,
    this.characterHappyAsset,
    this.characterCelebrateAsset,
    this.characterErrorAsset,
    required this.baseBackgroundColor,
    required this.primaryActionColor,
    required this.secondaryActionColor,
    required this.accentColor,
    required this.cardColor,
    required this.disabledBackgroundColor,
  });

  final AppTheme theme;

  final String backgroundAsset;
  final String questHeroAsset;
  final String characterAsset;
  
  /// Legacy: defaults to characterIdleAsset if available, otherwise used directly
  final String characterLottieAsset;

  /// Preferred runtime character asset (Rive). Keep null until a .riv exists.
  final String? characterRiveAsset;

  /// Optional state machine name inside the .riv file.
  final String? characterRiveStateMachine;

  /// If true and [characterRiveAsset] is set, UI should prefer Rive for character.
  final bool preferRiveCharacter;
  
  /// New: separate animation states
  /// If null, falls back to characterLottieAsset as idle animation
  final String? characterIdleAsset;
  final String? characterHappyAsset;
  final String? characterCelebrateAsset;
  final String? characterErrorAsset;

  final Color baseBackgroundColor;
  final Color primaryActionColor;
  final Color secondaryActionColor;
  final Color accentColor;

  /// Semi-transparent card/surface used on top of themed backgrounds.
  final Color cardColor;

  /// Used for disabled answer buttons etc.
  final Color disabledBackgroundColor;
  
  /// Get the animation asset for a given character state
  /// Falls back to characterLottieAsset if specific state not available
  String getCharacterAnimation(CharacterAnimationState state) {
    return switch (state) {
      CharacterAnimationState.idle => characterIdleAsset ?? characterLottieAsset,
      CharacterAnimationState.happy => characterHappyAsset ?? (characterIdleAsset ?? characterLottieAsset),
      CharacterAnimationState.celebrate => characterCelebrateAsset ?? (characterIdleAsset ?? characterLottieAsset),
      CharacterAnimationState.error => characterErrorAsset ?? (characterIdleAsset ?? characterLottieAsset),
    };
  }

  bool get shouldUseRiveCharacter =>
      preferRiveCharacter &&
      characterRiveAsset != null &&
      characterRiveAsset!.isNotEmpty;

  static AppThemeConfig forTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.jungle:
        return const AppThemeConfig(
          theme: AppTheme.jungle,
          backgroundAsset: 'assets/images/themes/jungle/background.png',
          questHeroAsset: 'assets/images/themes/jungle/quest_hero.png',
          characterAsset: 'assets/images/themes/jungle/character_v2.png',
          characterLottieAsset: 'assets/animations/ville_jungle_idle.json',
          characterRiveAsset: 'assets/characters/ville/rive/ville_character.riv',
          characterRiveStateMachine: 'VilleStateMachine',
          // New: separate animation states for more dynamic character
          characterIdleAsset: 'assets/animations/ville_jungle_idle.json',
          characterHappyAsset: 'assets/animations/ville_jungle_happy.json',
          characterCelebrateAsset: 'assets/animations/ville_jungle_celebrate.json',
          characterErrorAsset: 'assets/animations/ville_jungle_error.json',
          baseBackgroundColor: AppColors.jungleBackground,
          primaryActionColor: AppColors.junglePrimary,
          secondaryActionColor: AppColors.jungleSecondary,
          accentColor: AppColors.jungleAccent,
          cardColor: Color(0xCC2A4F36),
          disabledBackgroundColor: Color(0xCC3D6C50),
        );
      case AppTheme.space:
      case AppTheme.underwater:
      case AppTheme.fantasy:
        return const AppThemeConfig(
          theme: AppTheme.space,
          backgroundAsset: 'assets/images/themes/space/background.png',
          questHeroAsset: 'assets/images/themes/space/quest_hero.png',
          characterAsset: 'assets/images/themes/space/character.png',
          characterLottieAsset: 'assets/animations/ville_space_idle.json',
          characterRiveAsset: 'assets/characters/ville/rive/ville_character.riv',
          characterRiveStateMachine: 'VilleStateMachine',
          // New: separate animation states (fallback to idle for now)
          characterIdleAsset: 'assets/animations/ville_space_idle.json',
          characterHappyAsset: 'assets/animations/ville_space_happy.json',
          characterCelebrateAsset: 'assets/animations/ville_space_celebrate.json',
          characterErrorAsset: 'assets/animations/ville_space_error.json',
          baseBackgroundColor: AppColors.spaceBackground,
          primaryActionColor: AppColors.spacePrimary,
          secondaryActionColor: AppColors.spaceSecondary,
          accentColor: AppColors.spaceAccent,
          cardColor: Color(0xCC485466),
          disabledBackgroundColor: Color(0xCC5B6575),
        );
    }
  }

  ColorScheme colorScheme() {
    return ColorScheme.light(
      primary: primaryActionColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      surface: AppColors.neutralBackground,
      onSurface: AppColors.textPrimary,
      error: AppColors.wrongAnswer,
      onError: Colors.white,
    );
  }

  ThemeData themeData() {
    final scheme = colorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: baseBackgroundColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppConstants.minTouchTargetSize,
          ),
          backgroundColor: primaryActionColor,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: AppConstants.buttonFontSize,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppConstants.minTouchTargetSize,
          ),
          foregroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.buttonFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.square(AppConstants.minTouchTargetSizeSmall),
          foregroundColor: scheme.secondary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.onPrimary.withValues(alpha: AppOpacities.subtleFill),
        labelStyle: TextStyle(
          color: scheme.onPrimary.withValues(alpha: AppOpacities.mutedText),
        ),
        hintStyle: TextStyle(
          color: scheme.onPrimary.withValues(alpha: AppOpacities.subtleText),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(
            color: scheme.onPrimary.withValues(
              alpha: AppOpacities.borderMedium,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: scheme.secondary),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: scheme.onPrimary),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            baseBackgroundColor.withValues(alpha: AppOpacities.menuSurface),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onPrimary.withValues(alpha: AppOpacities.divider),
        thickness: 1,
      ),
    );
  }
}
