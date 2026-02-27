import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../domain/entities/question.dart';
import '../widgets/answer_button.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/progress_indicator_bar.dart';
import '../widgets/question_card.dart';
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

  @override
  void initState() {
    super.initState();
    _questionStartTime = DateTime.now();
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ResultsScreen(),
        ),
      );
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

    if (session == null || session.currentQuestion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      });

      return const Scaffold(
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
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.spaceBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Fråga ${session.currentQuestionIndex + 1} av ${session.totalQuestions}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding.w),
              child: ProgressIndicatorBar(progress: progress),
            ),

            SizedBox(height: AppConstants.largePadding.h),

            // Question card
            Expanded(
              child: QuestionCard(question: question),
            ),

            // Answer buttons
            Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding.w),
              child: _buildAnswerButtons(question),
            ),

            SizedBox(height: AppConstants.defaultPadding.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButtons(Question question) {
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
            onPressed: () => _handleAnswerSelected(answer),
          ),
        );
      }).toList(),
    );
  }
}
