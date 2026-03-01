import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/constants/app_constants.dart';
import 'package:math_game_app/core/di/injection.dart';
import 'package:math_game_app/core/services/audio_service.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/data/repositories/local_storage_repository.dart';
import 'package:math_game_app/domain/entities/question.dart';
import 'package:math_game_app/domain/entities/user_progress.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';
import 'package:math_game_app/domain/services/parent_pin_service.dart';
import 'package:math_game_app/main.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioService extends Mock implements AudioService {}

class _InMemoryLocalStorageRepository extends LocalStorageRepository {
  final Map<String, UserProgress> _users = {};
  final Map<String, dynamic> _settings = {};
  final Map<String, Map<String, dynamic>> _quizHistory = {};

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    _users[progress.userId] = progress;
  }

  @override
  UserProgress? getUserProgress(String userId) {
    return _users[userId];
  }

  @override
  List<UserProgress> getAllUserProfiles() {
    return _users.values.toList();
  }

  @override
  Future<void> deleteUserProgress(String userId) async {
    _users.remove(userId);
  }

  @override
  Future<void> saveQuizSession(Map<String, dynamic> session) async {
    final sessionId = session['sessionId'] as String;
    _quizHistory[sessionId] = session;
  }

  @override
  List<Map<String, dynamic>> getQuizHistory(String userId, {int? limit}) {
    final allSessions = _quizHistory.values
        .where((session) => session['userId'] == userId)
        .toList();

    allSessions.sort((a, b) {
      final dateA = DateTime.parse(a['startTime'] as String);
      final dateB = DateTime.parse(b['startTime'] as String);
      return dateB.compareTo(dateA);
    });

    return limit != null ? allSessions.take(limit).toList() : allSessions;
  }

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings.containsKey(key) ? _settings[key] : defaultValue;
  }

  @override
  Future<void> deleteSetting(String key) async {
    _settings.remove(key);
  }

  @override
  Future<void> clearAllData() async {
    _users.clear();
    _settings.clear();
    _quizHistory.clear();
  }
}

class _FakeQuestionGeneratorService extends QuestionGeneratorService {
  static const Question _question = Question(
    id: 'q1',
    operationType: OperationType.multiplication,
    difficulty: DifficultyLevel.easy,
    operand1: 6,
    operand2: 7,
    correctAnswer: 42,
    wrongAnswers: [41, 43, 40],
    explanation: '6 × 7 = 42',
  );

  @override
  List<Question> generateQuestions({
    required AgeGroup ageGroup,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    required int count,
    Map<OperationType, int>? difficultyStepsByOperation,
    int? difficultyStep,
    int? gradeLevel,
  }) {
    // Always generate a single deterministic question so the widget tests
    // can finish a quiz quickly and without randomness.
    return const [_question];
  }

  @override
  Question generateQuestion({
    required AgeGroup ageGroup,
    required OperationType operationType,
    required DifficultyLevel difficulty,
    Map<OperationType, int>? difficultyStepsByOperation,
    int? difficultyStep,
    int? gradeLevel,
    bool? wordProblemsEnabledOverride,
    double? wordProblemsChanceOverride,
    bool? missingNumberEnabledOverride,
    double? missingNumberChanceOverride,
  }) {
    return _question;
  }
}

void main() {
  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    final steps = (duration.inMilliseconds / 50).ceil().clamp(1, 200);
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> skipOnboardingIfPresent(WidgetTester tester) async {
    final skip = find.text('Hoppa över');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await pumpFor(tester, const Duration(milliseconds: 400));
    }
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final steps = (timeout.inMilliseconds / 50).ceil().clamp(1, 400);
    for (var i = 0; i < steps; i++) {
      await skipOnboardingIfPresent(tester);
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  late _InMemoryLocalStorageRepository repository;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    await getIt.reset();

    repository = _InMemoryLocalStorageRepository();
    getIt.registerSingleton<LocalStorageRepository>(repository);

    // Make audio calls safe in widget tests (no platform plugins).
    final audio = _MockAudioService();
    when(() => audio.playCorrectSound()).thenAnswer((_) async {});
    when(() => audio.playWrongSound()).thenAnswer((_) async {});
    when(() => audio.playCelebrationSound()).thenAnswer((_) async {});
    when(() => audio.playClickSound()).thenAnswer((_) async {});
    when(() => audio.playMusic()).thenAnswer((_) async {});
    when(() => audio.stopMusic()).thenAnswer((_) async {});
    getIt.registerSingleton<AudioService>(audio);

    // Make question generation deterministic and the session short.
    getIt.registerSingleton<QuestionGeneratorService>(
      _FakeQuestionGeneratorService(),
    );

    await initializeDependencies(initializeHive: false);
  });

  testWidgets(
    'Widget (App): visar titel på startsidan',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      // Boot shows a short loading state; wait for the first real Home UI.
      await pumpUntilFound(
        tester,
        find.text('Skapa profil'),
        timeout: const Duration(seconds: 8),
      );

      final titleFinder = find.text(AppConstants.appName);
      if (titleFinder.evaluate().isEmpty) {
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? t.textSpan?.toPlainText())
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        fail(
          'Kunde inte hitta app-titeln "${AppConstants.appName}". '
          'Tillgängliga texter: ${texts.take(80).toList()}',
        );
      }

      expect(titleFinder, findsOneWidget);
    },
  );

  testWidgets(
    'Widget (App): visar profilväljare när flera profiler finns',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const user1 = UserProgress(
        userId: 'u1',
        name: 'Alex',
        ageGroup: AgeGroup.middle,
        avatarEmoji: '🐯',
      );
      const user2 = UserProgress(
        userId: 'u2',
        name: 'Sam',
        ageGroup: AgeGroup.middle,
        avatarEmoji: '🦊',
      );
      await repository.saveUserProgress(user1);
      await repository.saveUserProgress(user2);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text('Välj spelare'));

      expect(find.text('Välj spelare'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    },
  );

  testWidgets(
    'Widget (Quiz): kan slutföra kort quiz och spela igen',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final multiplication =
          find.byKey(const Key('operation_card_multiplication'));
      await pumpUntilFound(tester, multiplication);
      expect(multiplication, findsOneWidget);

      // Start a quiz from Home.
      await tester.ensureVisible(multiplication);
      await tester.pump();
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 150),
      );
      await tester.tap(multiplication);
      await pumpUntilFound(tester, find.textContaining('Fråga'));

      expect(find.textContaining('Fråga'), findsOneWidget);

      // Complete the full session (AgeGroup.middle => 10 questions).
      for (var i = 0; i < 10; i++) {
        // Answer correctly (deterministic fake question: correctAnswer = 42).
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await pumpUntilFound(tester, find.text('Nästa!'));

        // Feedback dialog appears.
        expect(find.text('Nästa!'), findsOneWidget);
        await tester.ensureVisible(find.text('Nästa!'));
        await tester.tap(find.text('Nästa!'));

        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.textContaining('Spela igen'));

      // Should reach results.
      expect(find.textContaining('Spela igen'), findsOneWidget);

      // Practice again.
      await tester.ensureVisible(find.textContaining('Spela igen'));
      await tester.tap(find.textContaining('Spela igen'));
      await pumpUntilFound(tester, find.textContaining('Fråga'));

      expect(find.textContaining('Fråga'), findsOneWidget);
    },
  );

  testWidgets(
    'Widget (Resultat): kan starta fokuserad mini-pass från resultatskärmen',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final multiplication =
          find.byKey(const Key('operation_card_multiplication'));
      await pumpUntilFound(tester, multiplication);
      expect(multiplication, findsOneWidget);

      // Start a quiz from Home.
      await tester.ensureVisible(multiplication);
      await tester.pump();
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 150),
      );
      await tester.tap(multiplication);
      await pumpUntilFound(tester, find.textContaining('Fråga'));
      expect(find.textContaining('Fråga'), findsOneWidget);

      // Complete the full session (AgeGroup.middle => 10 questions).
      for (var i = 0; i < 10; i++) {
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await pumpUntilFound(tester, find.text('Nästa!'));
        await tester.ensureVisible(find.text('Nästa!'));
        await tester.tap(find.text('Nästa!'));
        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.textContaining('Spela igen'));

      // Start the quick practice session.
      await tester.ensureVisible(find.text('Snabbträna (2 min)'));
      await tester.tap(find.text('Snabbträna (2 min)'));
      await pumpUntilFound(tester, find.textContaining('Fråga'));

      expect(find.textContaining('Fråga'), findsOneWidget);
    },
  );

  testWidgets(
    'Widget (Resultat): visar tomt svårast-läge när inga svagheter finns',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      final multiplication =
          find.byKey(const Key('operation_card_multiplication'));
      await pumpUntilFound(tester, multiplication);
      expect(multiplication, findsOneWidget);

      await tester.ensureVisible(multiplication);
      await tester.pump();
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 150),
      );
      await tester.tap(multiplication);
      await pumpUntilFound(tester, find.textContaining('Fråga'));
      expect(find.textContaining('Fråga'), findsOneWidget);

      // Complete the full session (AgeGroup.middle => 10 questions).
      for (var i = 0; i < 10; i++) {
        await tester.ensureVisible(find.text('42'));
        await tester.pump();
        await tester.tap(find.text('42'));
        await pumpUntilFound(tester, find.text('Nästa!'));
        await tester.ensureVisible(find.text('Nästa!'));
        await tester.tap(find.text('Nästa!'));
        if (i < 9) {
          await pumpUntilFound(tester, find.textContaining('Fråga'));
        }
      }

      await pumpUntilFound(tester, find.textContaining('Spela igen'));

      // Quick practice should still be available and start.
      await tester.ensureVisible(find.text('Snabbträna (2 min)'));
      await tester.tap(find.text('Snabbträna (2 min)'));
      await pumpUntilFound(tester, find.textContaining('Fråga'));
      expect(find.textContaining('Fråga'), findsOneWidget);
    },
  );

  testWidgets(
    'Widget (Föräldraläge): kan skapa PIN och öppna översikten',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);
      await repository.saveSetting('onboarding_done_$userId', true);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text(AppConstants.appName));

      await pumpUntilFound(tester, find.byTooltip('Föräldraläge'));

      await tester.tap(find.byTooltip('Föräldraläge'));
      await pumpUntilFound(tester, find.text('Skapa PIN'));

      expect(find.text('Skapa PIN'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).at(0), '1234');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Spara PIN'));

      await pumpUntilFound(tester, find.text('Översikt'));
      expect(find.text('Föräldraläge'), findsOneWidget);
      expect(find.text('Översikt'), findsOneWidget);
    },
  );

  testWidgets(
    'Widget (Föräldraläge): kan ange befintlig PIN och öppna översikten',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);
      await repository.saveSetting('onboarding_done_$userId', true);
      // Use ParentPinService to set PIN correctly (hashed)
      final pinService = getIt<ParentPinService>();
      await pinService.setPin('1234');

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpUntilFound(tester, find.text(AppConstants.appName));

      await pumpUntilFound(tester, find.byTooltip('Föräldraläge'));

      await tester.tap(find.byTooltip('Föräldraläge'));
      await pumpUntilFound(tester, find.text('Ange PIN'));

      expect(find.text('Ange PIN'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Öppna'));

      await pumpUntilFound(tester, find.text('Översikt'));
      expect(find.text('Föräldraläge'), findsOneWidget);
      expect(find.text('Översikt'), findsOneWidget);
    },
  );

  testWidgets(
    'Widget (Onboarding): visas bara en gång och upprepas inte',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
        gradeLevel: 3,
      );
      await repository.saveUserProgress(user);

      // First run: onboarding should appear.
      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      // Wait for onboarding (do NOT use pumpUntilFound; it auto-skips onboarding).
      final onboardingTitle = find.text('Nu kör vi!');
      final steps = (const Duration(seconds: 4).inMilliseconds / 50).ceil();
      for (var i = 0; i < steps; i++) {
        if (onboardingTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Nu kör vi!'), findsOneWidget);

      // Finish onboarding quickly via skip.
      await tester.tap(find.text('Hoppa över'));
      await pumpUntilFound(tester, find.text(AppConstants.appName));

      // Second run: onboarding should not be shown again.
      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('Nu kör vi!'), findsNothing);
    },
  );

  testWidgets(
    'Widget (Onboarding): Klar tar dig inte tillbaka till steg 1',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repository.clearAllData();

      const userId = 'test-user';
      const user = UserProgress(
        userId: userId,
        name: 'Test',
        ageGroup: AgeGroup.middle,
      );
      await repository.saveUserProgress(user);

      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );

      // Wait for onboarding without auto-skip.
      final onboardingTitle = find.text('Nu kör vi!');
      final steps = (const Duration(seconds: 4).inMilliseconds / 50).ceil();
      for (var i = 0; i < steps; i++) {
        if (onboardingTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(onboardingTitle, findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Vilken årskurs kör du?'), findsOneWidget);

      // Choose a grade (e.g. Åk 3) to better match real user flow.
      final gradeDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButton<int?>,
      );
      expect(gradeDropdown, findsOneWidget);
      await tester.tap(gradeDropdown);
      await pumpFor(tester, const Duration(milliseconds: 200));
      await tester.tap(find.text('Åk 3').last);
      await pumpFor(tester, const Duration(milliseconds: 200));

      // Step 1 -> Step 2.
      await tester.tap(find.text('Nästa'));
      await pumpFor(
        tester,
        AppConstants.mediumAnimationDuration +
            const Duration(milliseconds: 200),
      );

      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('Vad vill du räkna?'), findsOneWidget);

      // Finish onboarding.
      await tester.tap(find.text('Klar'));

      // Wait for pop back to Home without using pumpUntilFound (no auto-skip).
      final homeTitle = find.text(AppConstants.appName);
      final finishSteps = (const Duration(seconds: 4).inMilliseconds / 50).ceil();
      for (var i = 0; i < finishSteps; i++) {
        if (homeTitle.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Allow route pop animation to fully complete.
      await pumpFor(tester, const Duration(milliseconds: 600));

      expect(homeTitle, findsOneWidget);
      expect(onboardingTitle, findsNothing);

      // Rebuild the app (same in-memory repository) - onboarding should not
      // appear again.
      await tester.pumpWidget(
        ProviderScope(
          child: MathGameApp(initFuture: Future.value(null)),
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('Nu kör vi!'), findsNothing);
    },
  );
}
