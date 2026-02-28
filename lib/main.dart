import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/providers/app_theme_provider.dart';
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

class MathGameApp extends ConsumerWidget {
  const MathGameApp({super.key, required this.bootstrapError});

  final String? bootstrapError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final theme = ref.watch(appThemeDataProvider);

        return MaterialApp(
          title: 'Siffersafari',
          debugShowCheckedModeBanner: false,
          theme: theme,
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
