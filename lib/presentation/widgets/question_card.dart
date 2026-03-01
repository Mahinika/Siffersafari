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
    final isEquationPrompt = question.promptText?.contains('=') ?? false;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On some layouts (short cards / smaller devices), large typography
              // can overflow vertically. Keep the same UI but scale down styles
              // slightly when height is tight.
              final compact = constraints.maxHeight < 210;

              final symbolStyle = (isWordProblem || compact)
                  ? Theme.of(context).textTheme.displayMedium
                  : Theme.of(context).textTheme.displayLarge;

              final questionStyle = isWordProblem
                  ? Theme.of(context).textTheme.headlineSmall
                  : (compact
                      ? Theme.of(context).textTheme.headlineLarge
                      : Theme.of(context).textTheme.displayLarge);

              final symbolGap = compact
                  ? AppConstants.smallPadding.h
                  : AppConstants.defaultPadding.h;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isEquationPrompt) ...[
                      Text(
                        question.operationType.symbol,
                        style: symbolStyle?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: questionTextColor ?? scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: symbolGap),
                    ],
                    Text(
                      question.questionText,
                      style: questionStyle?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: questionTextColor ?? scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: isWordProblem ? 4 : 1,
                      overflow: isWordProblem
                          ? TextOverflow.ellipsis
                          : TextOverflow.fade,
                    ),
                    SizedBox(height: AppConstants.smallPadding.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Vad blir resultatet?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: subtitleTextColor ??
                                  scheme.onSurface.withValues(alpha: 0.70),
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
