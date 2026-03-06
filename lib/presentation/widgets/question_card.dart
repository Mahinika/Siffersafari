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
    final resolvedBorderColor =
        borderColor ?? scheme.onPrimary.withValues(alpha: AppOpacities.cardBorder);
    final resolvedAccentColor = shadowColor ?? scheme.secondary;

    final isWordProblem = question.promptText != null;
    final isEquationPrompt = question.promptText?.contains('=') ?? false;

    return Semantics(
      label: 'Fråga: ${question.questionText}. Vad blir resultatet?',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 210 || constraints.maxWidth < 280;
            final veryCompact = constraints.maxHeight < 170;
            final ultraCompact = constraints.maxHeight < 120;

            final textTheme = Theme.of(context).textTheme;

            final cardPadding = compact
                ? (isWordProblem
                    ? AppConstants.smallPadding.w
                    : AppConstants.defaultPadding.w)
                : AppConstants.largePadding.w;

            final symbolStyle = compact
                ? textTheme.headlineMedium
                : (isWordProblem
                    ? textTheme.displayMedium
                    : textTheme.displayLarge);

            final questionStyle = isWordProblem
              ? (compact ? textTheme.titleMedium : textTheme.headlineSmall)
              : (compact ? textTheme.headlineLarge : textTheme.displayLarge);

            final symbolGap = compact
                ? (AppConstants.smallPadding.h * 0.25)
                : AppConstants.defaultPadding.h;

            final subtitleGap = compact
              ? AppConstants.microSpacing6.h
              : AppConstants.smallPadding.h;

            final wordProblemMaxLines = veryCompact ? 3 : 5;
            final questionMaxLines = isWordProblem ? wordProblemMaxLines : 2;
            final helperText = isWordProblem
              ? 'Läs lugnt och välj rätt svar.'
              : 'Välj rätt svar.';

            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding.w,
              ),
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: resolvedCardColor,
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius * 2),
                border: Border.all(
                  color: resolvedBorderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: resolvedAccentColor
                        .withValues(alpha: AppOpacities.cardShadow),
                    blurRadius: AppConstants.questionCardShadowBlur,
                    offset:
                        const Offset(0, AppConstants.questionCardShadowOffsetY),
                  ),
                ],
              ),
              child: ultraCompact
                  ? Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          question.questionText,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: questionTextColor ?? scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppConstants.smallPadding.w,
                          runSpacing: AppConstants.microSpacing6.h,
                          children: [
                            _QuestionMetaChip(
                              text:
                                  '${question.operationType.emoji} ${question.operationType.displayName}',
                              textColor: questionTextColor ?? scheme.onSurface,
                              backgroundColor: resolvedAccentColor.withValues(
                                alpha: AppOpacities.accentFillSubtle,
                              ),
                              borderColor: resolvedAccentColor.withValues(
                                alpha: AppOpacities.highlightStrong,
                              ),
                            ),
                            _QuestionMetaChip(
                              text: isWordProblem
                                  ? 'Textuppgift'
                                  : question.difficulty.displayName,
                              textColor: subtitleTextColor ??
                                  scheme.onSurface.withValues(
                                    alpha: AppOpacities.mutedText,
                                  ),
                              backgroundColor: scheme.onSurface.withValues(
                                alpha: AppOpacities.subtleFill,
                              ),
                              borderColor: scheme.onSurface.withValues(
                                alpha: AppOpacities.cardBorder,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: compact
                              ? AppConstants.smallPadding.h
                              : AppConstants.defaultPadding.h,
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 520.w),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!isEquationPrompt) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact
                                              ? AppConstants.smallPadding.w
                                              : AppConstants.defaultPadding.w,
                                          vertical: compact
                                              ? AppConstants.microSpacing6.h
                                              : AppConstants.smallPadding.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: resolvedAccentColor.withValues(
                                            alpha:
                                                AppOpacities.accentFillSubtle,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppConstants.borderRadius * 1.5,
                                          ),
                                          border: Border.all(
                                            color:
                                                resolvedAccentColor.withValues(
                                              alpha:
                                                  AppOpacities.highlightStrong,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          question.operationType.symbol,
                                          style: symbolStyle?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: questionTextColor ??
                                                scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: symbolGap),
                                    ],
                                    Text(
                                      question.questionText,
                                      style: questionStyle?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: questionTextColor ??
                                            scheme.onSurface,
                                        height: isWordProblem ? 1.2 : 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: questionMaxLines,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: subtitleGap),
                                    Text(
                                      helperText,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: subtitleTextColor ??
                                            scheme.onSurface.withValues(
                                              alpha: AppOpacities.mutedText,
                                            ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionMetaChip extends StatelessWidget {
  const _QuestionMetaChip({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String text;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding.w,
        vertical: AppConstants.microSpacing6.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.25),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
