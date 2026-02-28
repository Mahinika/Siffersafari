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
  Future<void> clearAllData() async {
    _users.clear();
    _settings.clear();
    _quizHistory.clear();
  }
}

class _FakeQuestionGeneratorService extends QuestionGeneratorService {
  @override
  List<Question> generateQuestions({
    required ageGroup,
    required operationType,
    required difficulty,
    required int count,
  }) {
    // Always generate a single deterministic question so the widget tests
    // can finish a quiz quickly and without randomness.
    return const [
      Question(
        id: 'q1',
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
        operand1: 6,
        operand2: 7,
        correctAnswer: 42,
        wrongAnswers: [41, 43, 40],
        explanation: '6 × 7 = 42',
      ),
    ];
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

  testWidgets('App shows title on home', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
      ),
    );

    // Let post-frame callbacks + first frame settle.
    await pumpUntilFound(tester, find.text(AppConstants.appName));

    expect(find.text(AppConstants.appName), findsOneWidget);
  });

  testWidgets('Can complete a short quiz and practice again',
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
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
      ),
    );

    final multiplication = find.text(OperationType.multiplication.displayName);
    await pumpUntilFound(tester, multiplication);
    if (multiplication.evaluate().isEmpty) {
      // In smaller test viewports the second row of operation cards may be
      // off-screen; scroll the grid until the card is visible.
      await tester.scrollUntilVisible(
        multiplication,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    expect(multiplication, findsOneWidget);

    // Start a quiz from Home.
    await tester.tap(multiplication);
    await pumpUntilFound(tester, find.textContaining('Fråga'));

    expect(find.textContaining('Fråga'), findsOneWidget);

    // Answer correctly (deterministic fake question: correctAnswer = 42).
    await tester.tap(find.text('42'));
    await pumpUntilFound(tester, find.text('Fortsätt'));

    // Feedback dialog appears.
    expect(find.text('Fortsätt'), findsOneWidget);
    await tester.ensureVisible(find.text('Fortsätt'));
    await tester.tap(find.text('Fortsätt'));
    await pumpUntilFound(tester, find.text('Spela igen'));

    // Should reach results.
    expect(find.text('Spela igen'), findsOneWidget);

    // Practice again.
    await tester.ensureVisible(find.text('Spela igen'));
    await tester.tap(find.text('Spela igen'));
    await pumpUntilFound(tester, find.textContaining('Fråga'));

    expect(find.textContaining('Fråga'), findsOneWidget);
  });

  testWidgets('Can start focused mini-pass from results',
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
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
      ),
    );

    final multiplication = find.text(OperationType.multiplication.displayName);
    await pumpUntilFound(tester, multiplication);
    if (multiplication.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        multiplication,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    // Start a quiz from Home.
    await tester.tap(multiplication);
    await pumpUntilFound(tester, find.textContaining('Fråga'));

    // Answer correctly (deterministic fake question: correctAnswer = 42).
    await tester.tap(find.text('42'));
    await pumpUntilFound(tester, find.text('Fortsätt'));
    await tester.ensureVisible(find.text('Fortsätt'));
    await tester.tap(find.text('Fortsätt'));
    await pumpUntilFound(tester, find.text('Spela igen'));

    // Start the focused mini-pass.
    await tester.ensureVisible(find.text('Öva på det svåraste (2 min)'));
    await tester.tap(find.text('Öva på det svåraste (2 min)'));
    await pumpUntilFound(tester, find.textContaining('Fråga'));

    expect(find.textContaining('Fråga'), findsOneWidget);
  });

  testWidgets('Shows empty hardest-state when no weaknesses',
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
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
      ),
    );

    final multiplication = find.text(OperationType.multiplication.displayName);
    await pumpUntilFound(tester, multiplication);
    if (multiplication.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        multiplication,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    await tester.tap(multiplication);
    await pumpUntilFound(tester, find.textContaining('Fråga'));

    // Answer correctly quickly.
    await tester.tap(find.text('42'));
    await pumpUntilFound(tester, find.text('Fortsätt'));
    await tester.ensureVisible(find.text('Fortsätt'));
    await tester.tap(find.text('Fortsätt'));
    await pumpUntilFound(tester, find.text('Spela igen'));

    // With no wrong answers and no slow answers, the hardest panel should show
    // the empty-state message.
    expect(find.text('Inget särskilt – riktigt bra jobbat!'), findsOneWidget);

    // The focused mini-pass should still be available and start.
    await tester.ensureVisible(find.text('Öva på det svåraste (2 min)'));
    await tester.tap(find.text('Öva på det svåraste (2 min)'));
    await pumpUntilFound(tester, find.textContaining('Fråga'));
    expect(find.textContaining('Fråga'), findsOneWidget);
  });

  testWidgets('Can create a new parent PIN and open parent dashboard',
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
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
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
  });

  testWidgets('Can enter existing parent PIN and open parent dashboard',
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
    await repository.saveSetting('parent_pin', '1234');

    await tester.pumpWidget(
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
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
  });

  testWidgets('Onboarding is shown once and then not repeated',
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
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
      ),
    );

    // Wait for onboarding (do NOT use pumpUntilFound; it auto-skips onboarding).
    final onboardingTitle = find.text('Kom igång');
    final steps = (const Duration(seconds: 4).inMilliseconds / 50).ceil();
    for (var i = 0; i < steps; i++) {
      if (onboardingTitle.evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Kom igång'), findsOneWidget);

    // Finish onboarding quickly via skip.
    await tester.tap(find.text('Hoppa över'));
    await pumpUntilFound(tester, find.text(AppConstants.appName));

    // Second run: onboarding should not be shown again.
    await tester.pumpWidget(
      const ProviderScope(
        child: MathGameApp(bootstrapError: null),
      ),
    );

    await pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Kom igång'), findsNothing);
  });
}
