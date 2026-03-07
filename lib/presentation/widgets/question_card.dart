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

  double _resolveEquationFontSize(
    BuildContext context, {
    required TextStyle? baseStyle,
    required String text,
    required double maxWidth,
    required bool compact,
  }) {
    final candidates = compact
        ? <double>[44, 40, 36, 32, 28]
        : <double>[64, 58, 52, 46, 40, 34];
    final textScaler = MediaQuery.textScalerOf(context);

    for (final fontSize in candidates) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: baseStyle?.copyWith(fontSize: fontSize),
        ),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        maxLines: 1,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines && painter.width <= maxWidth) {
        return fontSize;
      }
    }

    return candidates.last;
  }

  double _resolveWordProblemFontSize(
    BuildContext context, {
    required TextStyle? baseStyle,
    required String text,
    required double maxWidth,
    required int maxLines,
    required bool compact,
  }) {
    final candidates = compact
        ? <double>[26, 24, 22, 20, 18]
        : <double>[34, 32, 30, 28, 26, 24, 22];
    final textScaler = MediaQuery.textScalerOf(context);

    for (final fontSize in candidates) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: baseStyle?.copyWith(fontSize: fontSize),
        ),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        maxLines: maxLines,
        ellipsis: '...',
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines) {
        return fontSize;
      }
    }

    return candidates.last;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedCardColor = (cardColor ?? scheme.surface).withValues(
      alpha: 1.0,
    );
    final resolvedBorderColor = borderColor ??
        scheme.onPrimary.withValues(alpha: AppOpacities.cardBorder);
    final resolvedAccentColor = shadowColor ?? scheme.secondary;

    final isEquationPrompt = question.promptText?.contains('=') ?? false;
    final isWordProblem = question.promptText != null && !isEquationPrompt;

    return Semantics(
      label: 'Fråga: ${question.displayQuestionText}. Vad blir resultatet?',
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
            final maxQuestionWidth =
                constraints.maxWidth < 520.w ? constraints.maxWidth : 520.w;

            final questionStyle = isWordProblem
                ? (compact ? textTheme.titleMedium : textTheme.headlineSmall)
                : (compact ? textTheme.headlineLarge : textTheme.displayLarge);
            final wordProblemMaxLines = veryCompact ? 3 : 5;
            final questionMaxLines = isWordProblem ? wordProblemMaxLines : 2;
            final wordProblemFontSize = !isWordProblem
                ? null
                : _resolveWordProblemFontSize(
                    context,
                    baseStyle: questionStyle?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: questionTextColor ?? scheme.onSurface,
                      height: 1.2,
                    ),
                    text: question.displayQuestionText,
                    maxWidth: maxQuestionWidth,
                    maxLines: questionMaxLines,
                    compact: compact,
                  );
            final equationFontSize = isWordProblem
                ? null
                : _resolveEquationFontSize(
                    context,
                    baseStyle: questionStyle?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: questionTextColor ?? scheme.onSurface,
                      height: 1.0,
                    ),
                    text: question.displayQuestionText,
                    maxWidth: maxQuestionWidth,
                    compact: compact,
                  );

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
                    color: resolvedAccentColor.withValues(
                      alpha: AppOpacities.cardShadow,
                    ),
                    blurRadius: AppConstants.questionCardShadowBlur,
                    offset:
                        const Offset(0, AppConstants.questionCardShadowOffsetY),
                  ),
                ],
              ),
              child: ultraCompact
                  ? Center(
                      child: Text(
                        question.displayQuestionText,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: questionTextColor ?? scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: maxQuestionWidth),
                              child: isWordProblem
                                  ? Text(
                                      question.displayQuestionText,
                                      style: questionStyle?.copyWith(
                                        fontSize: wordProblemFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: questionTextColor ??
                                            scheme.onSurface,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: questionMaxLines,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text(
                                      question.displayQuestionText,
                                      style: questionStyle?.copyWith(
                                        fontSize: equationFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: questionTextColor ??
                                            scheme.onSurface,
                                        height: 1.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
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
