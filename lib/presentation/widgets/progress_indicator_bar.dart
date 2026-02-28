import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';

class ProgressIndicatorBar extends StatelessWidget {
  const ProgressIndicatorBar({
    required this.progress,
    this.backgroundColor,
    this.valueColor,
    super.key,
  });

  final double progress;
  final Color? backgroundColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      label: 'Framsteg',
      value: '$percent procent',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12.h,
            backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? AppColors.spaceAccent,
            ),
          ),
        ),
      ),
    );
  }
}
