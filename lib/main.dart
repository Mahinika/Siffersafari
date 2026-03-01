import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/providers/app_theme_provider.dart';
import 'core/theme/app_theme_config.dart';
import 'domain/enums/app_theme.dart';
import 'presentation/screens/app_entry_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  // Global error handling for async errors outside Flutter framework
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Platform error: $error');
    debugPrintStack(stackTrace: stack);
    return true; // Prevent crash
  };

  // Global error handling for isolate errors
  Isolate.current.addErrorListener(
    RawReceivePort((dynamic pair) {
      final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
      debugPrint('Isolate error: ${errorAndStacktrace.first}');
    }).sendPort,
  );

  // Register services/repositories up front so providers (e.g. theme) can
  // resolve GetIt dependencies during the first build.
  // Hive boxes are opened later in [_initializeAsync].
  await _measureAsync(
    'initializeDependencies(initializeHive: false)',
    () => initializeDependencies(initializeHive: false),
  );

  final initCompleter = Completer<String?>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Important: run heavy init *after* the first frame has fully rasterized.
    // A post-frame callback still runs on the UI thread; by scheduling another
    // task we avoid blocking first-frame rasterization.
    Future<void>(() async {
      try {
        initCompleter.complete(await _initializeAsync());
      } catch (e, st) {
        debugPrint('Deferred initialization failed: $e');
        debugPrintStack(stackTrace: st);
        initCompleter.complete(e.toString());
      }
    });
  });

  // Show app immediately with loading indicator while Hive boxes open in background
  runApp(
    ProviderScope(
      child: MathGameApp(
        initFuture: initCompleter.future,
      ),
    ),
  );
}

Future<String?> _initializeAsync() async {
  try {
    await _measureAsync('Hive.initFlutter', () => Hive.initFlutter());

    await _measureAsync(
      'initializeDependencies(openQuizHistoryBox: false)',
      () => initializeDependencies(openQuizHistoryBox: false),
    );

    // Open quiz_history box after core dependencies (non-blocking)
    unawaited(
      _measureAsync('Hive.openBox(quiz_history)', () async {
        await Hive.openBox('quiz_history');
      }).catchError((e) {
        debugPrint('quiz_history box open failed: $e');
      }),
    );

    return null; // Success
  } catch (e, st) {
    debugPrint('Initialization failed: $e');
    debugPrintStack(stackTrace: st);
    return e.toString();
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
  const MathGameApp({super.key, required this.initFuture});

  final Future<String?> initFuture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultTheme = AppThemeConfig.forTheme(AppTheme.space).themeData();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return FutureBuilder<String?>(
          future: initFuture,
          builder: (context, snapshot) {
            final isDone = snapshot.connectionState == ConnectionState.done;
            final initError = isDone ? snapshot.data : null;

            final theme = (isDone && initError == null)
                ? ref.watch(appThemeDataProvider)
                : defaultTheme;

            final Widget home;
            if (!isDone) {
              home = const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (initError != null) {
              home = _BootstrapErrorScreen(error: initError);
            } else {
              home = const AppEntryScreen();
            }

            return MaterialApp(
              title: 'Siffersafari',
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: home,
            );
          },
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
