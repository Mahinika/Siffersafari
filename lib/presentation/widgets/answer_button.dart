import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    required this.answer,
    required this.onPressed,
    this.isSelected = false,
    this.isCorrect,
    super.key,
  });

  final int answer;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (isCorrect != null) {
      // After answer is submitted
      if (isCorrect!) {
        backgroundColor = AppColors.correctAnswer;
        textColor = Colors.white;
      } else if (isSelected) {
        backgroundColor = AppColors.wrongAnswer;
        textColor = Colors.white;
      } else {
        backgroundColor = Colors.grey.shade300;
        textColor = AppColors.textPrimary;
      }
    } else {
      // Before answer is submitted
      backgroundColor = isSelected ? AppColors.spacePrimary : Colors.white;
      textColor = isSelected ? Colors.white : AppColors.textPrimary;
    }

    final isEnabled = isCorrect == null;
    final String label;

    if (isCorrect != null) {
      if (isCorrect!) {
        label = 'Svar $answer, rätt svar';
      } else if (isSelected) {
        label = 'Svar $answer, fel svar';
      } else {
        label = 'Svar $answer';
      }
    } else {
      label = isSelected ? 'Svar $answer, valt' : 'Svar $answer';
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: ExcludeSemantics(
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            minimumSize: Size(double.infinity, 64.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            elevation: isSelected ? 4 : 2,
          ),
          child: Text(
            answer.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
