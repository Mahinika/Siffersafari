import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/feedback_service.dart';

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
    const incorrectColor = AppColors.wrongAnswer;
    final scheme = Theme.of(context).colorScheme;
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
            // Icon
            ExcludeSemantics(
              child: Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? correctColor : incorrectColor,
                size: AppConstants.feedbackDialogIconSize.sp,
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
                        color: isCorrect ? correctColor : incorrectColor,
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
                child: Text(
                  widget.feedback.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: widget.messageTextColor ??
                            scheme.onSurface.withValues(alpha: 0.70),
                      ),
                  textAlign: TextAlign.center,
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
                'Fortsätt',
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
}
