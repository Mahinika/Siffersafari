import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/audio_service.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/enums/operation_type.dart';
import '../widgets/star_rating.dart';
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

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: Text('Ingen data tillgänglig'),
        ),
      );
    }

    final shouldCelebrate =
        session.successRate >= 0.8 || (reward?.unlockedIds.isNotEmpty ?? false);
    final stars = _calculateStars(session.successRate);
    final timeText = _formatDuration(session.sessionDuration);
    final hardest = _getHardestQuestions(session);

    return Scaffold(
      backgroundColor: AppColors.spaceBackground,
      body: SafeArea(
        child: LayoutBuilder(
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
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: AppConstants.largePadding.h),

                    if (shouldCelebrate) ...[
                      SizedBox(
                        height: 140.h,
                        child: Lottie.asset(
                          'assets/animations/celebration.json',
                          fit: BoxFit.contain,
                          repeat: false,
                        ),
                      ),
                      SizedBox(height: AppConstants.largePadding.h),
                    ],

                    // Star rating
                    StarRating(stars: stars),

                    SizedBox(height: AppConstants.largePadding.h * 2),

                    // Stats card
                    Container(
                      padding: EdgeInsets.all(AppConstants.largePadding.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            context,
                            'Rätt svar',
                            '${session.correctAnswers} / ${session.totalQuestions}',
                          ),
                          SizedBox(height: AppConstants.defaultPadding.h),
                          _buildStatRow(
                            context,
                            'Tid',
                            timeText,
                          ),
                          SizedBox(height: AppConstants.defaultPadding.h),
                          _buildStatRow(
                            context,
                            'Poäng',
                            session.totalPoints.toString(),
                          ),
                          SizedBox(height: AppConstants.defaultPadding.h),
                          _buildStatRow(
                            context,
                            'Ditt mål idag',
                            '${userState.dailyGoalProgressToday}/${userState.dailyGoalTarget}',
                          ),
                          if (reward != null && reward.bonusPoints > 0) ...[
                            SizedBox(height: AppConstants.defaultPadding.h),
                            _buildStatRow(
                              context,
                              'Bonuspoäng',
                              '+${reward.bonusPoints}',
                            ),
                          ],
                          SizedBox(height: AppConstants.defaultPadding.h),
                          _buildStatRow(
                            context,
                            'Framgångsfrekvens',
                            '${(session.successRate * 100).toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppConstants.largePadding.h),

                    _buildHardestPanel(context, hardest),

                    if (reward != null && reward.unlockedIds.isNotEmpty) ...[
                      SizedBox(height: AppConstants.largePadding.h),
                      _buildAchievementPanel(context, reward),
                    ],

                    SizedBox(height: AppConstants.largePadding.h * 2),

                    // Buttons
                    ElevatedButton(
                      onPressed: () {
                        final user = ref.read(userProvider).activeUser;
                        if (user == null) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
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
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
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
                                operationType: session.operationType,
                                difficulty: effectiveDifficulty,
                              );
                        } else {
                          ref.read(quizProvider.notifier).startCustomSession(
                                operationType: session.operationType,
                                difficulty: effectiveDifficulty,
                                questions: miniQuestions,
                              );
                        }

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const QuizScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.spacePrimary,
                        minimumSize: Size(double.infinity, 56.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      child: Text(
                        'Öva på det svåraste (2 min)',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
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
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
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
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
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

                        ref.read(quizProvider.notifier).startSession(
                              ageGroup: effectiveAgeGroup,
                              operationType: session.operationType,
                              difficulty: effectiveDifficulty,
                            );

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const QuizScreen()),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        minimumSize: Size(double.infinity, 56.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      child: Text(
                        'Spela igen',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
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
                        'Tillbaka till Start',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white70,
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
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
        SizedBox(width: AppConstants.smallPadding.w),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAchievementPanel(
    BuildContext context,
    AchievementReward reward,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.defaultPadding.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upplåsta prestationer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppConstants.smallPadding.h),
          ...reward.unlockedIds.map(
            (id) => Text(
              '• ${AchievementService().getDisplayName(id)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardestPanel(
    BuildContext context,
    List<_HardestQuestion> hardest,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.defaultPadding.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Svårast idag',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppConstants.smallPadding.h),
          if (hardest.isEmpty)
            Text(
              'Inget särskilt – riktigt bra jobbat!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            )
          else
            ...hardest.map((item) {
              final q = item.question;
              final time = item.time;
              final answer = item.answer;

              final detailParts = <String>[];
              if (answer != null && !item.wasCorrect) {
                detailParts.add('Du svarade: $answer');
                detailParts.add('Rätt: ${q.correctAnswer}');
              }
              if (time != null && time != Duration.zero) {
                detailParts.add('Tid: ${time.inSeconds}s');
              }

              final details = detailParts.join(' • ');

              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${q.questionText}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getTitle(int stars) {
    switch (stars) {
      case 3:
        return 'Fantastiskt jobbat!';
      case 2:
        return 'Bra jobbat!';
      case 1:
        return 'Bra kämpat!';
      default:
        return 'Fortsätt öva!';
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
