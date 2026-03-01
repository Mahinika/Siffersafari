import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/word_problems_settings_provider.dart';
import '../../core/services/audio_service.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/enums/operation_type.dart';
import '../widgets/star_rating.dart';
import '../widgets/themed_background_scaffold.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _applied = false;

  static const int _slowAnswerThresholdSeconds = 8;

  List<_HardestQuestion> _getHardestQuestions(QuizSession session) {
    final items = <_HardestQuestion>[];

    for (final q in session.questions) {
      final answer = session.answers[q.id];
      final time = session.responseTimes[q.id];
      if (answer == null && time == null) continue;

      // Only show actual "hard" items:
      // - wrong answers always count
      // - correct answers only count if they were slow
      final wasCorrect = answer != null ? q.isCorrect(answer) : true;
      final isSlow = (time?.inSeconds ?? 0) >= _slowAnswerThresholdSeconds;
      final include = !wasCorrect || isSlow;
      if (!include) continue;

      items.add(
        _HardestQuestion(
          question: q,
          answer: answer,
          wasCorrect: wasCorrect,
          time: time,
        ),
      );
    }

    // Wrong answers first, then slowest response time.
    items.sort((a, b) {
      if (a.wasCorrect != b.wasCorrect) {
        return a.wasCorrect ? 1 : -1;
      }
      final at = a.time?.inMilliseconds ?? 0;
      final bt = b.time?.inMilliseconds ?? 0;
      return bt.compareTo(at);
    });

    if (items.length <= 3) return items;
    return items.take(3).toList(growable: false);
  }

  List<Question> _buildFocusedMiniPassQuestions(
    QuizSession session,
    List<_HardestQuestion> hardest,
    int count,
  ) {
    if (count <= 0) return const [];

    final weakQuestions =
        hardest.map((h) => h.question).toList(growable: false);

    final correctFast = <Question>[];
    final timed = <({Question q, int ms})>[];

    for (final q in session.questions) {
      final answer = session.answers[q.id];
      if (answer == null) continue;
      if (!q.isCorrect(answer)) continue;

      final ms = session.responseTimes[q.id]?.inMilliseconds;
      if (ms == null) {
        correctFast.add(q);
      } else {
        timed.add((q: q, ms: ms));
      }
    }

    timed.sort((a, b) => a.ms.compareTo(b.ms));
    correctFast
      ..addAll(timed.map((e) => e.q))
      ..removeWhere((q) => weakQuestions.contains(q));

    final weakCount = ((count * 0.8).round()).clamp(1, count);
    final easyCount = (count - weakCount).clamp(0, count);

    final result = <Question>[];

    if (weakQuestions.isEmpty) {
      // Fallback: no clear "hard" items, replay the quickest correct ones.
      final fallback = correctFast.isNotEmpty ? correctFast : session.questions;
      for (var i = 0; i < count; i++) {
        final q = fallback[i % fallback.length];
        result.add(q.copyWith(id: '${q.id}__focus_$i'));
      }
      return result;
    }

    // 70–80% focus on weak items.
    for (var i = 0; i < weakCount; i++) {
      final q = weakQuestions[i % weakQuestions.length];
      result.add(q.copyWith(id: '${q.id}__weak_$i'));
    }

    // 20–30% easier filler.
    final filler = correctFast.isNotEmpty
        ? correctFast
        : session.questions.where((q) => !weakQuestions.contains(q)).toList();
    for (var i = 0; i < easyCount; i++) {
      final q = filler.isNotEmpty
          ? filler[i % filler.length]
          : weakQuestions[i % weakQuestions.length];
      result.add(q.copyWith(id: '${q.id}__easy_$i'));
    }

    return result;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_applied) return;

    final session = ref.read(quizProvider).session;
    if (session != null) {
      ref.read(userProvider.notifier).applyQuizResult(session);

      final reward = ref.read(userProvider).lastReward;
      final shouldCelebrate = session.successRate >= 0.8 ||
          (reward?.unlockedIds.isNotEmpty ?? false);
      if (shouldCelebrate) {
        getIt<AudioService>().playCelebrationSound();
      }
      _applied = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final userState = ref.watch(userProvider);
    final session = quizState.session;
    final reward = userState.lastReward;

    final themeCfg = ref.watch(appThemeConfigProvider);

    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);

    if (session == null) {
      return ThemedBackgroundScaffold(
        body: Center(
          child: Text(
            'Ingen data tillgänglig',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    final shouldCelebrate =
        session.successRate >= 0.8 || (reward?.unlockedIds.isNotEmpty ?? false);
    final stars = _calculateStars(session.successRate);
    final timeText = _formatDuration(session.sessionDuration);
    final hardest = _getHardestQuestions(session);
    final bonusPoints = reward?.bonusPoints ?? 0;
    final totalPoints = session.totalPoints + bonusPoints;
    final panelColor = themeCfg.cardColor.withValues(alpha: 1.0);
    final didUnlockSomething = reward?.unlockedIds.isNotEmpty ?? false;

    final badgeTeaser = _buildBadgeTeaser(
      session: session,
      quizState: quizState,
      stars: stars,
      bonusPoints: bonusPoints,
      didUnlockSomething: didUnlockSomething,
    );

    return ThemedBackgroundScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppConstants.largePadding.w),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    _getTitle(stars),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppConstants.largePadding.h),

                  if (shouldCelebrate) ...[
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 650),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) {
                        final scale = 0.85 + (0.15 * t);
                        return Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        height: 150.h,
                        child: Lottie.asset(
                          'assets/animations/celebration.json',
                          fit: BoxFit.contain,
                          repeat: false,
                        ),
                      ),
                    ),
                  ],
                  // Star rating
                  StarRating(stars: stars),

                  SizedBox(height: AppConstants.largePadding.h),

                  // Stats card
                  Container(
                    padding: EdgeInsets.all(AppConstants.largePadding.w),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: onPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          context,
                          'Rätt!',
                          '${session.correctAnswers} / ${session.totalQuestions}',
                        ),
                        SizedBox(height: AppConstants.defaultPadding.h),
                        _buildStatRow(
                          context,
                          'Din tid',
                          timeText,
                        ),
                        SizedBox(height: AppConstants.defaultPadding.h),
                        _buildStatRow(
                          context,
                          'Dina poäng',
                          totalPoints.toString(),
                        ),
                        if (bonusPoints > 0) ...[
                          SizedBox(height: AppConstants.smallPadding.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Bonus +$bonusPoints!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: scheme.secondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: AppConstants.largePadding.h),

                  _buildBadgePanel(
                    context,
                    panelColor: panelColor,
                    onPrimary: onPrimary,
                    mutedOnPrimary: mutedOnPrimary,
                    badgeTeaser: badgeTeaser,
                  ),

                  SizedBox(height: AppConstants.largePadding.h),

                  // Buttons
                  ElevatedButton(
                    onPressed: () {
                      final user = ref.read(userProvider).activeUser;
                      if (user == null) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                        return;
                      }

                      // Respect parent settings (if present). If the operation is
                      // disabled, return to Home.
                      final allowedOps =
                          ref.read(parentSettingsProvider)[user.userId] ??
                              {
                                OperationType.addition,
                                OperationType.subtraction,
                                OperationType.multiplication,
                                OperationType.division,
                              };

                      if (!allowedOps.contains(session.operationType)) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                        return;
                      }

                      final effectiveAgeGroup =
                          DifficultyConfig.effectiveAgeGroup(
                        fallback: user.ageGroup,
                        gradeLevel: user.gradeLevel,
                      );

                      final effectiveDifficulty =
                          DifficultyConfig.effectiveDifficulty(
                        fallback: session.difficulty,
                        gradeLevel: user.gradeLevel,
                      );

                      final steps = DifficultyConfig.buildDifficultySteps(
                        storedSteps: user.operationDifficultySteps,
                        defaultDifficulty: effectiveDifficulty,
                      );

                      final repo = getIt<LocalStorageRepository>();
                      final rawWordProblemsEnabled = repo.getSetting(
                        wordProblemsEnabledKey(user.userId),
                        defaultValue: true,
                      );
                      final wordProblemsEnabled = rawWordProblemsEnabled is bool
                          ? rawWordProblemsEnabled
                          : true;

                      ref.read(quizProvider.notifier).startSession(
                            ageGroup: effectiveAgeGroup,
                            gradeLevel: user.gradeLevel,
                            operationType: session.operationType,
                            difficulty: effectiveDifficulty,
                            initialDifficultyStepsByOperation: steps,
                            wordProblemsEnabled: wordProblemsEnabled,
                          );

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Spela igen!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  OutlinedButton(
                    onPressed: () {
                      final user = ref.read(userProvider).activeUser;
                      if (user == null) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                        return;
                      }

                      // Respect parent settings (if present). If the operation is
                      // disabled, return to Home.
                      final allowedOps =
                          ref.read(parentSettingsProvider)[user.userId] ??
                              {
                                OperationType.addition,
                                OperationType.subtraction,
                                OperationType.multiplication,
                                OperationType.division,
                              };

                      if (!allowedOps.contains(session.operationType)) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                        return;
                      }

                      final effectiveAgeGroup =
                          DifficultyConfig.effectiveAgeGroup(
                        fallback: user.ageGroup,
                        gradeLevel: user.gradeLevel,
                      );

                      final effectiveDifficulty =
                          DifficultyConfig.effectiveDifficulty(
                        fallback: session.difficulty,
                        gradeLevel: user.gradeLevel,
                      );

                      final steps = DifficultyConfig.buildDifficultySteps(
                        storedSteps: user.operationDifficultySteps,
                        defaultDifficulty: effectiveDifficulty,
                      );

                      final repo = getIt<LocalStorageRepository>();
                      final rawWordProblemsEnabled = repo.getSetting(
                        wordProblemsEnabledKey(user.userId),
                        defaultValue: true,
                      );
                      final wordProblemsEnabled = rawWordProblemsEnabled is bool
                          ? rawWordProblemsEnabled
                          : true;

                      final count = DifficultyConfig.getQuestionsPerSession(
                        effectiveAgeGroup,
                      );

                      final miniQuestions = _buildFocusedMiniPassQuestions(
                        session,
                        hardest,
                        count,
                      );

                      if (miniQuestions.isEmpty) {
                        ref.read(quizProvider.notifier).startSession(
                              ageGroup: effectiveAgeGroup,
                              gradeLevel: user.gradeLevel,
                              operationType: session.operationType,
                              difficulty: effectiveDifficulty,
                              initialDifficultyStepsByOperation: steps,
                              wordProblemsEnabled: wordProblemsEnabled,
                            );
                      } else {
                        ref.read(quizProvider.notifier).startCustomSession(
                              operationType: session.operationType,
                              difficulty: effectiveDifficulty,
                              questions: miniQuestions,
                              ageGroup: effectiveAgeGroup,
                              gradeLevel: user.gradeLevel,
                              initialDifficultyStepsByOperation: steps,
                              wordProblemsEnabled: wordProblemsEnabled,
                            );
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Snabbträna (2 min)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  SizedBox(height: AppConstants.smallPadding.h),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Hem',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: mutedOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: mutedOnPrimary,
                ),
          ),
        ),
        SizedBox(width: AppConstants.smallPadding.w),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _getTitle(int stars) {
    switch (stars) {
      case 3:
        return 'Wow! Supersnyggt!';
      case 2:
        return 'Snyggt jobbat!';
      case 1:
        return 'Bra kämpat!';
      default:
        return 'Heja! Prova igen!';
    }
  }

  int _calculateStars(double successRate) {
    if (successRate >= 0.9) return 3;
    if (successRate >= 0.7) return 2;
    if (successRate >= 0.5) return 1;
    return 0;
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildBadgePanel(
    BuildContext context, {
    required Color panelColor,
    required Color onPrimary,
    required Color mutedOnPrimary,
    required _BadgeTeaser badgeTeaser,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.largePadding.w),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: onPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                badgeTeaser.badgeEmoji,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(width: AppConstants.defaultPadding.w),
              Expanded(
                child: Text(
                  badgeTeaser.badgeTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.smallPadding.h),
          Text(
            badgeTeaser.badgeBody,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: AppConstants.defaultPadding.h),
          Text(
            badgeTeaser.teaser,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  _BadgeTeaser _buildBadgeTeaser({
    required QuizSession session,
    required QuizState quizState,
    required int stars,
    required int bonusPoints,
    required bool didUnlockSomething,
  }) {
    final seed = session.sessionId;

    String badgeEmoji;
    String badgeTitle;
    String badgeBody;

    if (didUnlockSomething) {
      badgeEmoji = '🎁';
      badgeTitle = _pick(
        seed,
        const ['Ny skatt!', 'Upplåsning!', 'Du hittade en grej!'],
      );
      badgeBody = 'Du låste upp något nytt. Fortsätt så!';
    } else if (stars >= 3) {
      badgeEmoji = '🏆';
      badgeTitle =
          _pick(seed, const ['Stjärnkapten!', 'Mästarrunda!', 'Tre stjärnor!']);
      badgeBody =
          '3 stjärnor i ${session.operationType.emoji} ${session.operationType.displayName}.';
    } else if (quizState.bestCorrectStreak >= 5) {
      badgeEmoji = '🔥';
      badgeTitle =
          _pick(seed, const ['Svitproffs!', 'Du är i zonen!', 'Eldsvit!']);
      badgeBody = 'Bästa svit: ${quizState.bestCorrectStreak} rätt i rad.';
    } else if (quizState.speedBonusCount >= 3) {
      badgeEmoji = '⚡';
      badgeTitle =
          _pick(seed, const ['Blixtläge!', 'Snabbbonus-jägare!', 'Raketfart!']);
      badgeBody =
          'Snabbbonusar: ${quizState.speedBonusCount} st (supersnabbt!).';
    } else if (session.successRate >= 0.7) {
      badgeEmoji = '🌟';
      badgeTitle =
          _pick(seed, const ['Stabil runda!', 'Snyggt flow!', 'Bra tempo!']);
      badgeBody =
          'Du är på gång i ${session.operationType.emoji} ${session.operationType.displayName}.';
    } else {
      badgeEmoji = '💪';
      badgeTitle =
          _pick(seed, const ['Bra kämpat!', 'Du tränar!', 'Heja dig!']);
      badgeBody = 'Varje runda gör dig lite starkare.';
    }

    final teaser = _buildTeaser(
      session: session,
      quizState: quizState,
      stars: stars,
      bonusPoints: bonusPoints,
    );

    return _BadgeTeaser(
      badgeEmoji: badgeEmoji,
      badgeTitle: badgeTitle,
      badgeBody: badgeBody,
      teaser: teaser,
    );
  }

  String _buildTeaser({
    required QuizSession session,
    required QuizState quizState,
    required int stars,
    required int bonusPoints,
  }) {
    if (stars < 3) {
      final needed = ((session.totalQuestions * 0.9).ceil())
          .clamp(1, session.totalQuestions);
      return 'Nästa mål: 3 stjärnor — sikta på $needed av ${session.totalQuestions} rätt!';
    }

    if (quizState.speedBonusCount == 0) {
      return 'Bonusjakt: svara supersnabbt för ⚡!';
    }

    if (quizState.bestCorrectStreak < 5) {
      return 'Svitjakt: prova att få 5 rätt i rad 🔥';
    }

    if (bonusPoints == 0) {
      return 'Tips: Snabbträna övar på dina klurigaste!';
    }

    return 'Redo för en ny runda?';
  }

  String _pick(String seed, List<String> options) {
    if (options.isEmpty) return '';
    final index = _stableHash(seed) % options.length;
    return options[index];
  }

  int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _BadgeTeaser {
  const _BadgeTeaser({
    required this.badgeEmoji,
    required this.badgeTitle,
    required this.badgeBody,
    required this.teaser,
  });

  final String badgeEmoji;
  final String badgeTitle;
  final String badgeBody;
  final String teaser;
}

class _HardestQuestion {
  const _HardestQuestion({
    required this.question,
    required this.answer,
    required this.wasCorrect,
    required this.time,
  });

  final Question question;
  final int? answer;
  final bool wasCorrect;
  final Duration? time;
}
