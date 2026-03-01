import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../domain/entities/question.dart';
import '../widgets/answer_button.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/progress_indicator_bar.dart';
import '../widgets/question_card.dart';
import '../widgets/themed_background_scaffold.dart';
import 'home_screen.dart';
import 'results_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  DateTime? _questionStartTime;
  int? _selectedAnswer;
  String? _momentText;
  Timer? _momentTimer;

  static const int _showStreakFrom = 2;

  @override
  void initState() {
    super.initState();
    _questionStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _momentTimer?.cancel();
    super.dispose();
  }

  void _showMoment(String text) {
    _momentTimer?.cancel();
    setState(() {
      _momentText = text;
    });
    _momentTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _momentText = null;
      });
    });
  }

  void _handleAnswerSelected(int answer) {
    if (_selectedAnswer != null) return; // Already answered

    setState(() {
      _selectedAnswer = answer;
    });

    final responseTime = DateTime.now().difference(_questionStartTime!);
    final user = ref.read(userProvider).activeUser;

    if (user == null) return;

    final effectiveAgeGroup = DifficultyConfig.effectiveAgeGroup(
      fallback: user.ageGroup,
      gradeLevel: user.gradeLevel,
    );

    ref.read(quizProvider.notifier).submitAnswer(
          answer: answer,
          responseTime: responseTime,
          ageGroup: effectiveAgeGroup,
        );
  }

  void _handleNextQuestion() {
    final quizState = ref.read(quizProvider);
    final session = quizState.session;

    if (session == null) return;

    final nextIndex = session.currentQuestionIndex + 1;
    if (nextIndex >= session.totalQuestions) {
      // Ensure feedback is cleared so the post-frame dialog hook doesn't reopen
      // a dialog while we transition to Results.
      ref.read(quizProvider.notifier).clearFeedback();
      setState(() {
        _selectedAnswer = null;
      });
      context.pushReplacementSmooth(const ResultsScreen());
      return;
    }

    ref.read(quizProvider.notifier).goToNextQuestion();
    setState(() {
      _selectedAnswer = null;
      _questionStartTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen inside build (Riverpod requirement) and show small "moment" badges
    // when the user earns a streak milestone or a speed bonus.
    ref.listen<QuizState>(quizProvider, (previous, next) {
      if (!mounted) return;
      if (previous == null) return;

      final prevSessionId = previous.session?.sessionId;
      final nextSessionId = next.session?.sessionId;
      if (nextSessionId == null) return;
      if (prevSessionId != null && prevSessionId != nextSessionId) return;

      final prevSpeed = previous.speedBonusCount;
      final nextSpeed = next.speedBonusCount;
      if (nextSpeed > prevSpeed) {
        _showMoment('⚡ Snabbbonus!');
        return;
      }

      final prevStreak = previous.correctStreak;
      final nextStreak = next.correctStreak;

      if (prevStreak >= _showStreakFrom && nextStreak == 0) {
        // Keep it gentle: missing once shouldn't feel like a punishment.
        _showMoment('💛 Ny svit på gång!');
        return;
      }

      if (nextStreak > prevStreak) {
        final message = switch (nextStreak) {
          2 => '🔥 Svit! 2 i rad!',
          3 => '🔥 Okej! 3 i rad!',
          5 => '🔥 WOW! 5 i rad!',
          8 => '🔥 Galet! 8 i rad!',
          _ => null,
        };
        if (message != null) {
          _showMoment(message);
        }
      }
    });

    final quizState = ref.watch(quizProvider);
    final session = quizState.session;
    final feedback = quizState.feedback;

    final themeCfg = ref.watch(appThemeConfigProvider);
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;

    final primaryActionColor = themeCfg.primaryActionColor;
    final accentColor = themeCfg.accentColor;
    final cardColor = themeCfg.cardColor;
    final cardBorderColor = onPrimary.withValues(alpha: 0.14);
    final lightTextColor = onPrimary;
    final mutedTextColor = onPrimary.withValues(alpha: 0.70);

    if (session == null || session.currentQuestion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushAndRemoveUntilSmooth(
          const HomeScreen(),
          (route) => false,
        );
      });

      return const ThemedBackgroundScaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final question = session.currentQuestion!;
    final progress =
        (session.currentQuestionIndex + 1) / session.totalQuestions;

    // Show feedback dialog when available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (feedback != null && _selectedAnswer != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => FeedbackDialog(
            feedback: feedback,
            onContinue: _handleNextQuestion,
            continueButtonColor: primaryActionColor,
            dialogBackgroundColor: cardColor,
            messageTextColor: mutedTextColor,
          ),
        );
      }
    });

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: Text(
          'Fråga ${session.currentQuestionIndex + 1}/${session.totalQuestions}',
          style: TextStyle(color: onPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding.w),
            child: ProgressIndicatorBar(
              progress: progress,
              valueColor: accentColor,
              backgroundColor: onPrimary.withValues(alpha: 0.22),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding.w,
            ),
            child: _buildPlayHud(
              context,
              question: question,
              correctStreak: quizState.correctStreak,
              speedBonusCount: quizState.speedBonusCount,
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding.w,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _buildMissionText(
                  correctStreak: quizState.correctStreak,
                  speedBonusCount: quizState.speedBonusCount,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),

          if (_momentText != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding.w,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _momentText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),

          SizedBox(height: AppConstants.smallPadding.h),

          // Question card
          Expanded(
            child: QuestionCard(
              question: question,
              cardColor: cardColor,
              shadowColor: primaryActionColor,
              questionTextColor: lightTextColor,
              subtitleTextColor: mutedTextColor,
              borderColor: cardBorderColor,
            ),
          ),

          // Answer buttons
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding.w),
            child: _buildAnswerButtons(context, question),
          ),

          SizedBox(height: AppConstants.defaultPadding.h),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons(BuildContext context, Question question) {
    final themeCfg = ref.read(appThemeConfigProvider);
    final idleButtonColor = themeCfg.primaryActionColor;
    final selectedButtonColor = themeCfg.secondaryActionColor;
    final buttonDisabledColor = themeCfg.disabledBackgroundColor;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    final options = question.allAnswerOptions;

    return Column(
      children: options.map((answer) {
        final isSelected = _selectedAnswer == answer;
        final isCorrect = question.correctAnswer == answer;
        final showResult = _selectedAnswer != null;

        return Padding(
          padding: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
          child: AnswerButton(
            answer: answer,
            isSelected: isSelected,
            isCorrect: showResult ? isCorrect : null,
            selectedBackgroundColor: selectedButtonColor,
            idleBackgroundColor: idleButtonColor,
            idleTextColor: onPrimary,
            disabledBackgroundColor: buttonDisabledColor,
            onPressed: () => _handleAnswerSelected(answer),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayHud(
    BuildContext context, {
    required Question question,
    required int correctStreak,
    required int speedBonusCount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);

    final items = <Widget>[];

    if (speedBonusCount > 0) {
      items.add(
        _buildHudChip(
          context,
          text: '⚡ $speedBonusCount',
          accent: scheme.secondary,
        ),
      );
    }

    if (correctStreak >= _showStreakFrom) {
      items.add(
        _buildHudChip(
          context,
          text: '🔥 $correctStreak',
          accent: scheme.secondary,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '${question.operationType.emoji} ${question.operationType.displayName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (items.isNotEmpty) ...[
          SizedBox(width: AppConstants.smallPadding.w),
          ...items,
        ],
      ],
    );
  }

  Widget _buildHudChip(
    BuildContext context, {
    required String text,
    required Color accent,
  }) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding.w,
        vertical: (AppConstants.smallPadding / 2).h,
      ),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: onPrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  String _buildMissionText({
    required int correctStreak,
    required int speedBonusCount,
  }) {
    if (correctStreak < _showStreakFrom) {
      return 'Uppdrag: få $_showStreakFrom rätt i rad 🔥';
    }

    if (correctStreak < 5) {
      return 'Uppdrag: sikta på 5 i rad 🔥';
    }

    if (speedBonusCount == 0) {
      return 'Uppdrag: ta en snabbbonus ⚡ (supersnabbt!)';
    }

    return 'Uppdrag: fortsätt flowa!';
  }
}
