import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/app_theme.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/mastery_level.dart';
import '../../domain/enums/operation_type.dart';
import '../services/achievement_service.dart';
import '../services/adaptive_difficulty_service.dart';
import '../services/audio_service.dart';
import '../services/feedback_service.dart';
import '../services/quest_progression_service.dart';
import '../services/question_generator_service.dart';
import '../services/spaced_repetition_service.dart';

final getIt = GetIt.instance;

void _perf(String name, void Function() fn) {
  if (!kProfileMode) {
    fn();
    return;
  }

  final sw = Stopwatch()..start();
  try {
    fn();
  } finally {
    sw.stop();
    debugPrint('[PERF] $name: ${sw.elapsedMilliseconds}ms');
  }
}

Future<T> _perfAsync<T>(String name, Future<T> Function() fn) async {
  if (!kProfileMode) return fn();

  final sw = Stopwatch()..start();
  try {
    return await fn();
  } finally {
    sw.stop();
    debugPrint('[PERF] $name: ${sw.elapsedMilliseconds}ms');
  }
}

/// Initialize all dependencies
Future<void> initializeDependencies({
  bool initializeHive = true,
  bool openQuizHistoryBox = true,
}) async {
  final total = kProfileMode ? (Stopwatch()..start()) : null;

  // Initialize Hive boxes
  if (initializeHive) {
    await _perfAsync(
      'initializeDependencies._initializeHive(openQuizHistoryBox: $openQuizHistoryBox)',
      () => _initializeHive(openQuizHistoryBox: openQuizHistoryBox),
    );
  }

  // Register repositories
  if (!getIt.isRegistered<LocalStorageRepository>()) {
    _perf('getIt.register(LocalStorageRepository)', () {
      getIt.registerLazySingleton<LocalStorageRepository>(
        () => LocalStorageRepository(),
      );
    });
  }

  // Register services
  if (!getIt.isRegistered<QuestionGeneratorService>()) {
    _perf('getIt.register(QuestionGeneratorService)', () {
      getIt.registerLazySingleton<QuestionGeneratorService>(
        () => QuestionGeneratorService(),
      );
    });
  }

  if (!getIt.isRegistered<AudioService>()) {
    _perf('getIt.register(AudioService)', () {
      getIt.registerLazySingleton<AudioService>(
        () => AudioService(),
      );
    });
  }

  if (!getIt.isRegistered<AdaptiveDifficultyService>()) {
    _perf('getIt.register(AdaptiveDifficultyService)', () {
      getIt.registerLazySingleton<AdaptiveDifficultyService>(
        () => AdaptiveDifficultyService(),
      );
    });
  }

  if (!getIt.isRegistered<SpacedRepetitionService>()) {
    _perf('getIt.register(SpacedRepetitionService)', () {
      getIt.registerLazySingleton<SpacedRepetitionService>(
        () => SpacedRepetitionService(),
      );
    });
  }

  if (!getIt.isRegistered<QuestProgressionService>()) {
    _perf('getIt.register(QuestProgressionService)', () {
      getIt.registerLazySingleton<QuestProgressionService>(
        () => const QuestProgressionService(),
      );
    });
  }

  if (!getIt.isRegistered<FeedbackService>()) {
    _perf('getIt.register(FeedbackService)', () {
      getIt.registerLazySingleton<FeedbackService>(
        () => FeedbackService(),
      );
    });
  }

  if (!getIt.isRegistered<AchievementService>()) {
    _perf('getIt.register(AchievementService)', () {
      getIt.registerLazySingleton<AchievementService>(
        () => AchievementService(),
      );
    });
  }

  if (total != null) {
    total.stop();
    debugPrint(
        '[PERF] initializeDependencies total: ${total.elapsedMilliseconds}ms');
  }
}

Future<void> _initializeHive({required bool openQuizHistoryBox}) async {
  // Register adapters
  // Register enum adapters first (used inside UserProgress)
  _perf('Hive.registerAdapter(enums + UserProgress)', () {
    Hive.registerAdapter(AgeGroupAdapter(), override: true);
    Hive.registerAdapter(OperationTypeAdapter(), override: true);
    Hive.registerAdapter(DifficultyLevelAdapter(), override: true);
    Hive.registerAdapter(AppThemeAdapter(), override: true);
    Hive.registerAdapter(MasteryLevelAdapter(), override: true);
    Hive.registerAdapter(UserProgressAdapter(), override: true);
  });

  // Open boxes
  final openFutures = <Future<void>>[
    _perfAsync("Hive.openBox('user_progress')", () async {
      await Hive.openBox('user_progress');
    }),
    _perfAsync("Hive.openBox('settings')", () async {
      await Hive.openBox('settings');
    }),
    if (openQuizHistoryBox)
      _perfAsync("Hive.openBox('quiz_history')", () async {
        await Hive.openBox('quiz_history');
      }),
  ];

  await _perfAsync('Hive.openBox(all required)', () async {
    await Future.wait(openFutures);
  });
}
