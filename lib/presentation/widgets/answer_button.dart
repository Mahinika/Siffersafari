import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';

class AnswerButton extends StatefulWidget {
  const AnswerButton({
    required this.answer,
    required this.onPressed,
    this.isSelected = false,
    this.isCorrect,
    this.selectedBackgroundColor,
    this.idleBackgroundColor,
    this.idleTextColor,
    this.disabledBackgroundColor,
    super.key,
  });

  final int answer;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool? isCorrect;
  final Color? selectedBackgroundColor;
  final Color? idleBackgroundColor;
  final Color? idleTextColor;
  final Color? disabledBackgroundColor;

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.microAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    Color textColor;

    if (widget.isCorrect != null) {
      // After answer is submitted
      if (widget.isCorrect!) {
        backgroundColor = AppColors.correctAnswer;
        textColor = scheme.onPrimary;
      } else if (widget.isSelected) {
        backgroundColor = AppColors.wrongAnswer;
        textColor = scheme.onPrimary;
      } else {
        backgroundColor = widget.disabledBackgroundColor ?? scheme.surface;
        textColor = widget.idleTextColor ?? scheme.onSurface;
      }
    } else {
      // Before answer is submitted
      backgroundColor = widget.isSelected
          ? (widget.selectedBackgroundColor ??
              Theme.of(context).colorScheme.primary)
          : (widget.idleBackgroundColor ?? scheme.surface);
      textColor = widget.isSelected
          ? scheme.onPrimary
          : (widget.idleTextColor ?? scheme.onSurface);
    }

    final isEnabled = widget.isCorrect == null;
    final String label;

    if (widget.isCorrect != null) {
      if (widget.isCorrect!) {
        label = 'Svar ${widget.answer}, rätt svar';
      } else if (widget.isSelected) {
        label = 'Svar ${widget.answer}, fel svar';
      } else {
        label = 'Svar ${widget.answer}';
      }
    } else {
      label = widget.isSelected
          ? 'Svar ${widget.answer}, valt'
          : 'Svar ${widget.answer}';
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTapDown: isEnabled ? _onTapDown : null,
            onTapUp: isEnabled ? _onTapUp : null,
            onTapCancel: isEnabled ? _onTapCancel : null,
            child: ElevatedButton(
              onPressed: isEnabled ? widget.onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                minimumSize:
                    Size(double.infinity, AppConstants.answerButtonHeight.h),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                elevation: widget.isSelected ? 6 : 3,
                shadowColor: widget.isSelected
                    ? backgroundColor.withValues(alpha: 0.5)
                    : Theme.of(context).shadowColor.withValues(alpha: 0.26),
              ),
              child: Text(
                widget.answer.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
