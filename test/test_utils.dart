import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siffersafari/core/di/injection.dart';
import 'package:siffersafari/core/services/audio_service.dart';
import 'package:siffersafari/core/services/question_generator_service.dart';
import 'package:siffersafari/data/repositories/local_storage_repository.dart';
import 'package:siffersafari/domain/entities/question.dart';
import 'package:siffersafari/domain/entities/user_progress.dart';
import 'package:siffersafari/domain/enums/age_group.dart';
import 'package:siffersafari/domain/enums/difficulty_level.dart';
import 'package:siffersafari/domain/enums/operation_type.dart';

// ============================================================================
// MOCK AUDIO SERVICE
// ============================================================================

/// Mock implementation of AudioService using Mocktail
class MockAudioService extends Mock implements AudioService {}

// ============================================================================
// IN-MEMORY STORAGE REPOSITORY
// ============================================================================

/// In-memory implementation of LocalStorageRepository for widget tests
///
/// Stores all data in memory without persisting to disk.
/// Useful for rapid test execution without Hive overhead.
class InMemoryLocalStorageRepository extends LocalStorageRepository {
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
  Future<void> deleteQuizSession(String sessionId) async {
    _quizHistory.remove(sessionId);
  }

  @override
  Future<void> purgeInProgressQuizSessions({
    required String userId,
    required String operationTypeName,
    String? exceptSessionId,
  }) async {
    final keys = _quizHistory.keys.toList(growable: false);
    for (final key in keys) {
      final session = _quizHistory[key];
      if (session == null) continue;

      if (exceptSessionId != null && session['sessionId'] == exceptSessionId) {
        continue;
      }

      if (session['userId'] != userId) continue;
      if (session['operationType'] != operationTypeName) continue;
      if (session['isComplete'] != false) continue;

      _quizHistory.remove(key);
    }
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

// ============================================================================
// FAKE QUESTION GENERATOR SERVICE
// ============================================================================

/// Fake implementation of QuestionGeneratorService for deterministic testing
///
/// Returns the same hardcoded question every time, so widget tests
/// can complete quiz flows quickly without randomness.
class FakeQuestionGeneratorService extends QuestionGeneratorService {
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

// ============================================================================
// HELPER FUNCTIONS FOR WIDGET TESTS
// ============================================================================

/// Pump the widget tree for a specified duration.
///
/// Breaks the duration into 50ms steps for smooth animation pumping.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final steps = (duration.inMilliseconds / 50).ceil().clamp(1, 200);
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Skip the onboarding screen if it's currently displayed.
///
/// Taps the "Hoppa över" button if found, then pumps for animations.
Future<void> skipOnboardingIfPresent(WidgetTester tester) async {
  // Avoid tapping unrelated "Hoppa över" buttons (e.g. dialogs).
  final isOnboardingVisible = find.text('Nu kör vi!').evaluate().isNotEmpty;
  if (!isOnboardingVisible) return;

  final skip = find.text('Hoppa över');
  if (skip.evaluate().isEmpty) return;

  await tester.ensureVisible(skip);
  await tester.tap(skip, warnIfMissed: false);
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Pump until a finder locates a widget or timeout is exceeded.
///
/// Automatically skips onboarding screens while waiting.
/// Pumps in 50ms intervals up to the timeout (default 4 seconds).
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

// ============================================================================
// SETUP HELPER FOR WIDGET TESTS
// ============================================================================

/// Initialize widget test dependencies and return the repository.
///
/// Call this in setUp() to set up all mocks and DI:
/// ```dart
/// late InMemoryLocalStorageRepository repository;
/// setUp(() async {
///   repository = await setupWidgetTestDependencies();
/// });
/// ```
Future<InMemoryLocalStorageRepository> setupWidgetTestDependencies() async {
  await getIt.reset();

  final repository = InMemoryLocalStorageRepository();
  getIt.registerSingleton<LocalStorageRepository>(repository);

  final audio = MockAudioService();
  when(() => audio.playCorrectSound()).thenAnswer((_) async {});
  when(() => audio.playWrongSound()).thenAnswer((_) async {});
  when(() => audio.playCelebrationSound()).thenAnswer((_) async {});
  when(() => audio.playClickSound()).thenAnswer((_) async {});
  when(() => audio.playMusic()).thenAnswer((_) async {});
  when(() => audio.stopMusic()).thenAnswer((_) async {});
  getIt.registerSingleton<AudioService>(audio);

  getIt.registerSingleton<QuestionGeneratorService>(
    FakeQuestionGeneratorService(),
  );

  await initializeDependencies(initializeHive: false);

  return repository;
}
