import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    this.cardColor,
    this.shadowColor,
    this.questionTextColor,
    this.subtitleTextColor,
    this.borderColor,
    super.key,
  });

  final Question question;
  final Color? cardColor;
  final Color? shadowColor;
  final Color? questionTextColor;
  final Color? subtitleTextColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedCardColor = (cardColor ?? scheme.surface).withValues(
      alpha: 1.0,
    );

    final isWordProblem = question.promptText != null;

    return Semantics(
      label: 'Fråga: ${question.questionText}. Vad blir resultatet?',
      child: ExcludeSemantics(
        child: Container(
          margin:
              EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
          padding: EdgeInsets.all(AppConstants.largePadding.w),
          decoration: BoxDecoration(
            color: resolvedCardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
            border: Border.all(
              color: borderColor ?? scheme.onPrimary.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? scheme.primary).withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  question.operationType.symbol,
                  style: (isWordProblem
                          ? Theme.of(context).textTheme.displayMedium
                          : Theme.of(context).textTheme.displayLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: questionTextColor ?? scheme.onSurface,
                  ),
                ),
                SizedBox(height: AppConstants.defaultPadding.h),
                Text(
                  question.questionText,
                  style: (isWordProblem
                          ? Theme.of(context).textTheme.headlineSmall
                          : Theme.of(context).textTheme.displayLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: questionTextColor ?? scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isWordProblem ? 4 : 1,
                  overflow:
                      isWordProblem ? TextOverflow.visible : TextOverflow.fade,
                ),
                SizedBox(height: AppConstants.smallPadding.h),
                Text(
                  'Vad blir resultatet?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: subtitleTextColor ??
                            scheme.onSurface.withValues(alpha: 0.70),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
