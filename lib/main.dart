import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? bootstrapError;
  try {
    await _measureAsync('Hive.initFlutter', () => Hive.initFlutter());
    await _measureAsync(
      'initializeDependencies(openQuizHistoryBox: false)',
      () => initializeDependencies(openQuizHistoryBox: false),
    );
  } catch (e, st) {
    bootstrapError = e.toString();
    debugPrint('Bootstrap failed: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(ProviderScope(child: MathGameApp(bootstrapError: bootstrapError)));

  if (bootstrapError == null) {
    // Open the potentially large history box in the background.
    unawaited(
      _measureAsync('Hive.openBox(quiz_history)', () async {
        await Hive.openBox('quiz_history');
      }).catchError((_) {}),
    );
  }
}

Future<T> _measureAsync<T>(String name, Future<T> Function() fn) async {
  if (!kProfileMode) return fn();

  final task = developer.TimelineTask(filterKey: 'perf');
  final sw = Stopwatch()..start();
  task.start(name);
  try {
    return await fn();
  } finally {
    sw.stop();
    task.finish();
    debugPrint('[PERF] $name: ${sw.elapsedMilliseconds}ms');
  }
}

class MathGameApp extends StatelessWidget {
  const MathGameApp({super.key, required this.bootstrapError});

  final String? bootstrapError;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final colorScheme = const ColorScheme.light(
          primary: AppColors.spacePrimary,
          onPrimary: Colors.white,
          secondary: AppColors.spaceAccent,
          onSecondary: Colors.white,
          surface: Color(0xFFFFF6E8),
          onSurface: AppColors.textPrimary,
          error: AppColors.wrongAnswer,
          onError: Colors.white,
        );

        return MaterialApp(
          title: 'Siffersafari',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: AppColors.neutralBackground,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppConstants.minTouchTargetSize,
                ),
                backgroundColor: AppColors.spacePrimary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.spaceSecondary,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          home: bootstrapError == null
              ? const HomeScreen()
              : _BootstrapErrorScreen(error: bootstrapError!),
        );
      },
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            'Kunde inte starta appen:\n$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
