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
      SemanticsService.announce(
        '${feedback.title}. ${feedback.message}',
        direction,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          widget.dialogBackgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.largePadding.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            ExcludeSemantics(
              child: Icon(
                widget.feedback.isCorrect ? Icons.check_circle : Icons.cancel,
                color: widget.feedback.isCorrect
                    ? AppColors.correctAnswer
                    : AppColors.wrongAnswer,
                size: 64.sp,
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
                        color: widget.feedback.isCorrect
                            ? AppColors.correctAnswer
                            : AppColors.wrongAnswer,
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
                        color:
                            widget.messageTextColor ?? AppColors.textSecondary,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.feedback.isCorrect
                    ? AppColors.correctAnswer
                    : (widget.continueButtonColor ?? AppColors.spacePrimary),
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Text(
                'Fortsätt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
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
