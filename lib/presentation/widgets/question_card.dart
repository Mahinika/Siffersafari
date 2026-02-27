import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    super.key,
  });

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fråga: ${question.questionText}. Vad blir resultatet?',
      child: ExcludeSemantics(
        child: Container(
          margin:
              EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
          padding: EdgeInsets.all(AppConstants.largePadding.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  question.operationType.emoji,
                  style: TextStyle(fontSize: 48.sp),
                ),
                SizedBox(height: AppConstants.defaultPadding.h),
                Text(
                  question.questionText,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.smallPadding.h),
                Text(
                  'Vad blir resultatet?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
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
