import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/app_theme.dart';
import '../theme/app_theme_config.dart';
import 'user_provider.dart';

final appThemeProvider = Provider<AppTheme>((ref) {
  final user = ref.watch(userProvider).activeUser;
  return user?.selectedTheme ?? AppTheme.space;
});

final appThemeConfigProvider = Provider<AppThemeConfig>((ref) {
  final theme = ref.watch(appThemeProvider);
  return AppThemeConfig.forTheme(theme);
});

final appThemeDataProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(appThemeConfigProvider);
  return config.themeData();
});
