import 'package:flutter/material.dart';

import '../../domain/enums/app_theme.dart';
import '../constants/app_constants.dart';

class AppThemeConfig {
  const AppThemeConfig({
    required this.theme,
    required this.backgroundAsset,
    required this.questHeroAsset,
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

  final Color baseBackgroundColor;
  final Color primaryActionColor;
  final Color secondaryActionColor;
  final Color accentColor;

  /// Semi-transparent card/surface used on top of themed backgrounds.
  final Color cardColor;

  /// Used for disabled answer buttons etc.
  final Color disabledBackgroundColor;

  static AppThemeConfig forTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.jungle:
        return const AppThemeConfig(
          theme: AppTheme.jungle,
          backgroundAsset: 'assets/images/themes/jungle/background.png',
          questHeroAsset: 'assets/images/themes/jungle/quest_hero.png',
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
            fontSize: 18,
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
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
        fillColor: scheme.onPrimary.withValues(alpha: 0.08),
        labelStyle: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.70)),
        hintStyle: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.54)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide:
              BorderSide(color: scheme.onPrimary.withValues(alpha: 0.2)),
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
            baseBackgroundColor.withValues(alpha: 0.98),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onPrimary.withValues(alpha: 0.24),
        thickness: 1,
      ),
    );
  }
}
