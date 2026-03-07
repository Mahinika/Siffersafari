import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/story_progress_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/adaptive_layout.dart';
import '../../core/utils/page_transitions.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/story_progress.dart';
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
    _momentTimer = Timer(AppConstants.momentDisplayDuration, () {
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
    final storyProgress = ref.watch(storyProgressProvider);

    final themeCfg = ref.watch(appThemeConfigProvider);
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;

    final primaryActionColor = themeCfg.primaryActionColor;
    final accentColor = themeCfg.accentColor;
    final cardColor = themeCfg.cardColor;
    final cardBorderColor = onPrimary.withValues(alpha: AppOpacities.hudBorder);
    final lightTextColor = onPrimary;
    final mutedTextColor = onPrimary.withValues(alpha: AppOpacities.mutedText);

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
          final useSplitLayout = layout.isExpandedWidth ||
              (layout.isLandscape && !layout.isCompactWidth);
          final maxContentWidth = useSplitLayout
              ? layout.contentMaxWidth
              : (layout.isMediumWidth ? 760.0 : double.infinity);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: useSplitLayout
                  ? _buildLandscapeLayout(
                      context,
                      question: question,
                      progress: progress,
                      quizState: quizState,
                      storyProgress: storyProgress,
                      primaryActionColor: primaryActionColor,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      cardBorderColor: cardBorderColor,
                      lightTextColor: lightTextColor,
                      mutedTextColor: mutedTextColor,
                      onPrimary: onPrimary,
                      scheme: scheme,
                      layout: layout,
                    )
                  : _buildPortraitLayout(
                      context,
                      question: question,
                      progress: progress,
                      quizState: quizState,
                      storyProgress: storyProgress,
                      primaryActionColor: primaryActionColor,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      cardBorderColor: cardBorderColor,
                      lightTextColor: lightTextColor,
                      mutedTextColor: mutedTextColor,
                      onPrimary: onPrimary,
                      scheme: scheme,
                      layout: layout,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context, {
    required Question question,
    required double progress,
    required QuizState quizState,
    required StoryProgress? storyProgress,
    required Color primaryActionColor,
    required Color accentColor,
    required Color cardColor,
    required Color cardBorderColor,
    required Color lightTextColor,
    required Color mutedTextColor,
    required Color onPrimary,
    required ColorScheme scheme,
    required AdaptiveLayoutInfo layout,
  }) {
    final questionFlex = layout.isShortHeight ? 5 : 6;
    final answersTopPadding = layout.isShortHeight
        ? AppConstants.smallPadding.h
        : AppConstants.defaultPadding.h;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding.w),
          child: ProgressIndicatorBar(
            progress: progress,
            valueColor: accentColor,
            backgroundColor:
                onPrimary.withValues(alpha: AppOpacities.progressTrack),
          ),
        ),
        Expanded(
          flex: questionFlex,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding.w,
                ),
                child: _buildStatusPanel(
                  context,
                  question: question,
                  storyProgress: storyProgress,
                  correctStreak: quizState.correctStreak,
                  speedBonusCount: quizState.speedBonusCount,
                  onPrimary: onPrimary,
                  scheme: scheme,
                ),
              ),
              SizedBox(height: AppConstants.smallPadding.h),
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
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.defaultPadding.w,
            answersTopPadding,
            AppConstants.defaultPadding.w,
            AppConstants.defaultPadding.w,
          ),
          child: _buildAnswerButtons(context, question),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context, {
    required Question question,
    required double progress,
    required QuizState quizState,
    required StoryProgress? storyProgress,
    required Color primaryActionColor,
    required Color accentColor,
    required Color cardColor,
    required Color cardBorderColor,
    required Color lightTextColor,
    required Color mutedTextColor,
    required Color onPrimary,
    required ColorScheme scheme,
    required AdaptiveLayoutInfo layout,
  }) {
    final questionFlex = layout.isExpandedWidth ? 58 : 54;
    final sideFlex = 100 - questionFlex;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding.w),
          child: ProgressIndicatorBar(
            progress: progress,
            valueColor: accentColor,
            backgroundColor:
                onPrimary.withValues(alpha: AppOpacities.progressTrack),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: questionFlex,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppConstants.defaultPadding.w,
                    right: AppConstants.smallPadding.w,
                    bottom: AppConstants.defaultPadding.h,
                  ),
                  child: QuestionCard(
                    question: question,
                    cardColor: cardColor,
                    shadowColor: primaryActionColor,
                    questionTextColor: lightTextColor,
                    subtitleTextColor: mutedTextColor,
                    borderColor: cardBorderColor,
                  ),
                ),
              ),
              Expanded(
                flex: sideFlex,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppConstants.smallPadding.w,
                    right: AppConstants.defaultPadding.w,
                    bottom: AppConstants.defaultPadding.h,
                  ),
                  child: Column(
                    children: [
                      _buildStatusPanel(
                        context,
                        question: question,
                        storyProgress: storyProgress,
                        correctStreak: quizState.correctStreak,
                        speedBonusCount: quizState.speedBonusCount,
                        onPrimary: onPrimary,
                        scheme: scheme,
                      ),
                      SizedBox(height: AppConstants.defaultPadding.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildAnswerButtons(context, question),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButtons(BuildContext context, Question question) {
    final themeCfg = ref.read(appThemeConfigProvider);
    final idleButtonColor = themeCfg.primaryActionColor;
    final selectedButtonColor = themeCfg.secondaryActionColor;
    final buttonDisabledColor = themeCfg.disabledBackgroundColor;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    final options = question.allAnswerOptions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 520 ||
            (constraints.maxWidth >= 320 && constraints.maxHeight < 520);
        final buttonMinHeight = constraints.maxHeight < 360
            ? 56.0
            : AppConstants.answerButtonHeight;

        final children = options.map((answer) {
          final isSelected = _selectedAnswer == answer;
          final isCorrect = question.correctAnswer == answer;
          final showResult = _selectedAnswer != null;

          final button = AnswerButton(
            answer: answer,
            isSelected: isSelected,
            isCorrect: showResult ? isCorrect : null,
            selectedBackgroundColor: selectedButtonColor,
            idleBackgroundColor: idleButtonColor,
            idleTextColor: onPrimary,
            disabledBackgroundColor: buttonDisabledColor,
            minHeight: buttonMinHeight,
            onPressed: () => _handleAnswerSelected(answer),
          );

          if (!useTwoColumns) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
              child: button,
            );
          }

          final spacing = AppConstants.smallPadding.w;
          final itemWidth = (constraints.maxWidth - spacing) / 2;
          return SizedBox(width: itemWidth, child: button);
        }).toList(growable: false);

        if (!useTwoColumns) {
          return Column(children: children);
        }

        return Wrap(
          spacing: AppConstants.smallPadding.w,
          runSpacing: AppConstants.smallPadding.h,
          children: children,
        );
      },
    );
  }

  Widget _buildStatusPanel(
    BuildContext context, {
    required Question question,
    required StoryProgress? storyProgress,
    required int correctStreak,
    required int speedBonusCount,
    required Color onPrimary,
    required ColorScheme scheme,
  }) {
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.defaultPadding.w),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: AppOpacities.panelFill),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: onPrimary.withValues(alpha: AppOpacities.hudBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayHud(
            context,
            question: question,
            correctStreak: correctStreak,
            speedBonusCount: speedBonusCount,
          ),
          if (storyProgress != null) ...[
            SizedBox(height: AppConstants.smallPadding.h),
            _buildStoryRibbon(
              context,
              storyProgress: storyProgress,
              accent: scheme.secondary,
              onPrimary: onPrimary,
            ),
          ],
          SizedBox(height: AppConstants.microSpacing6.h),
          Text(
            'Uppdrag nu',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
          SizedBox(height: AppConstants.microSpacing4.h),
          Text(
            _buildMissionText(
              correctStreak: correctStreak,
              speedBonusCount: speedBonusCount,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (_momentText != null) ...[
            SizedBox(height: AppConstants.smallPadding.h),
            _buildMomentBadge(
              context,
              text: _momentText!,
              accent: scheme.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryRibbon(
    BuildContext context, {
    required StoryProgress storyProgress,
    required Color accent,
    required Color onPrimary,
  }) {
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final currentNode = storyProgress.currentNode;
    final nextTitle = currentNode?.title ?? storyProgress.currentObjectiveTitle;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding.w,
        vertical: AppConstants.smallPadding.h,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppOpacities.accentFillSubtle),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: accent.withValues(alpha: AppOpacities.highlightStrong),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore, color: accent, size: 18),
              SizedBox(width: AppConstants.microSpacing6.w),
              Expanded(
                child: Text(
                  'Djungelspår',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              SizedBox(width: AppConstants.smallPadding.w),
              Flexible(
                child: Text(
                  storyProgress.chapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.microSpacing4.h),
          Text(
            'Ville: ${currentNode?.landmark ?? 'stigen'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: AppConstants.microSpacing2.h),
          Text(
            'Nästa mål: $nextTitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
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
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = constraints.maxWidth < 280 && items.isNotEmpty;
        final title = Text(
          '${question.operationType.emoji} ${question.operationType.displayName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: mutedOnPrimary,
                fontWeight: FontWeight.w800,
              ),
        );

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              SizedBox(height: AppConstants.microSpacing6.h),
              Wrap(
                spacing: AppConstants.smallPadding.w,
                runSpacing: AppConstants.microSpacing4.h,
                children: items,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            if (items.isNotEmpty) ...[
              SizedBox(width: AppConstants.smallPadding.w),
              Wrap(
                spacing: AppConstants.smallPadding.w,
                runSpacing: AppConstants.microSpacing4.h,
                children: items,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHudChip(
    BuildContext context, {
    required String text,
    required Color accent,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding.w,
        vertical: (AppConstants.smallPadding / 2).h,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppOpacities.accentFillSubtle),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: accent.withValues(alpha: AppOpacities.highlightStrong),
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

  Widget _buildMomentBadge(
    BuildContext context, {
    required String text,
    required Color accent,
  }) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding.w,
        vertical: AppConstants.smallPadding.h,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppOpacities.accentFillSubtle),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: accent.withValues(alpha: AppOpacities.highlightStrong),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: onPrimary,
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
