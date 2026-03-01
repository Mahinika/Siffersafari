import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({
    required this.feedback,
    required this.onContinue,
    this.continueButtonColor,
    this.dialogBackgroundColor,
    this.messageTextColor,
    super.key,
  });

  final FeedbackResult feedback;
  final VoidCallback onContinue;
  final Color? continueButtonColor;
  final Color? dialogBackgroundColor;
  final Color? messageTextColor;

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  bool _announced = false;

  List<String> _messageLines(String message) {
    return message
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;
    _announced = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final direction = Directionality.of(context);
      final feedback = widget.feedback;
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${feedback.title}. ${feedback.message}',
        direction,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.feedback.isCorrect;
    const correctColor = AppColors.correctAnswer;
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final mutedOnSurface = onSurface.withValues(alpha: 0.70);
    final lines = _messageLines(widget.feedback.message);

    final incorrectAccent = scheme.secondary;
    final mainColor = isCorrect ? correctColor : incorrectAccent;
    final buttonBackgroundColor = isCorrect
        ? correctColor
        : (widget.continueButtonColor ?? Theme.of(context).colorScheme.primary);

    final dialogBackgroundColor = widget.dialogBackgroundColor ??
        Theme.of(context).dialogTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;
    final dialogShape = Theme.of(context).dialogTheme.shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
        );

    return Dialog(
      backgroundColor: dialogBackgroundColor,
      shape: dialogShape,
      child: Padding(
        padding: EdgeInsets.all(AppConstants.largePadding.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: (AppConstants.feedbackDialogIconSize + 16).sp,
                height: (AppConstants.feedbackDialogIconSize + 16).sp,
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: mainColor.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.psychology_alt_rounded,
                  color: mainColor,
                  size: AppConstants.feedbackDialogIconSize.sp,
                ),
              ),
            ),

            SizedBox(height: AppConstants.defaultPadding.h),

            // Title
            Semantics(
              header: true,
              label: widget.feedback.title,
              child: ExcludeSemantics(
                child: Text(
                  widget.feedback.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(height: AppConstants.defaultPadding.h),

            // Message
            Semantics(
              label: widget.feedback.message,
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    if (lines.isNotEmpty)
                      Text(
                        lines.first,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color:
                                  widget.messageTextColor ?? mutedOnSurface,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    if (lines.length >= 2) ...[
                      SizedBox(height: AppConstants.smallPadding.h),
                      Text(
                        lines[1],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (lines.length >= 3) ...[
                      SizedBox(height: AppConstants.defaultPadding.h),
                      ..._buildExtraLines(
                        context,
                        lines.sublist(2),
                        defaultColor: widget.messageTextColor ?? mutedOnSurface,
                        accentColor: isCorrect ? correctColor : incorrectAccent,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: AppConstants.largePadding.h),

            // Continue button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onContinue();
              },
              style: (Theme.of(context).elevatedButtonTheme.style ??
                      const ButtonStyle())
                  .copyWith(
                backgroundColor: WidgetStatePropertyAll(buttonBackgroundColor),
                foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
              ),
              child: Text(
                'Nästa!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExtraLines(
    BuildContext context,
    List<String> extraLines, {
    required Color defaultColor,
    required Color accentColor,
  }) {
    final widgets = <Widget>[];

    for (final line in extraLines) {
      final isHintOrMeta = line.startsWith('💡') ||
          line.startsWith('⚡') ||
          line.startsWith('🔥') ||
          line.startsWith('🪙');

      widgets.add(
        Text(
          line,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isHintOrMeta ? accentColor : defaultColor,
                fontWeight: isHintOrMeta ? FontWeight.w800 : FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return widgets;
  }
}
