import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/adaptive_layout.dart';
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
  bool _feedbackDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _questionStartTime = DateTime.now();
  }

  void _handleAnswerSelected(int answer) {
    if (_selectedAnswer != null) return;

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
    final quizState = ref.watch(quizProvider);
    final session = quizState.session;
    final feedback = quizState.feedback;

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
    final isLastQuestion =
        session.currentQuestionIndex >= session.totalQuestions - 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (feedback != null &&
          _selectedAnswer != null &&
          !_feedbackDialogVisible) {
        _feedbackDialogVisible = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => FeedbackDialog(
            feedback: feedback,
            onContinue: _handleNextQuestion,
            continueLabel: isLastQuestion ? 'Se resultat' : 'Nästa',
            continueButtonColor: primaryActionColor,
            dialogBackgroundColor: cardColor,
            messageTextColor: mutedTextColor,
          ),
        ).whenComplete(() {
          _feedbackDialogVisible = false;
        });
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
                      primaryActionColor: primaryActionColor,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      cardBorderColor: cardBorderColor,
                      lightTextColor: lightTextColor,
                      mutedTextColor: mutedTextColor,
                      onPrimary: onPrimary,
                      layout: layout,
                    )
                  : _buildPortraitLayout(
                      context,
                      question: question,
                      progress: progress,
                      primaryActionColor: primaryActionColor,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      cardBorderColor: cardBorderColor,
                      lightTextColor: lightTextColor,
                      mutedTextColor: mutedTextColor,
                      onPrimary: onPrimary,
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
    required Color primaryActionColor,
    required Color accentColor,
    required Color cardColor,
    required Color cardBorderColor,
    required Color lightTextColor,
    required Color mutedTextColor,
    required Color onPrimary,
    required AdaptiveLayoutInfo layout,
  }) {
    final questionFlex = layout.isShortHeight ? 6 : 7;
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
          child: QuestionCard(
            question: question,
            cardColor: cardColor,
            shadowColor: primaryActionColor,
            questionTextColor: lightTextColor,
            subtitleTextColor: mutedTextColor,
            borderColor: cardBorderColor,
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
    required Color primaryActionColor,
    required Color accentColor,
    required Color cardColor,
    required Color cardBorderColor,
    required Color lightTextColor,
    required Color mutedTextColor,
    required Color onPrimary,
    required AdaptiveLayoutInfo layout,
  }) {
    final questionFlex = layout.isExpandedWidth ? 62 : 58;
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
                  child: SingleChildScrollView(
                    child: _buildAnswerButtons(context, question),
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
}
