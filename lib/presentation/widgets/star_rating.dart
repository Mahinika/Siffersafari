import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    required this.stars,
    super.key,
  });

  final int stars;

  @override
  Widget build(BuildContext context) {
    final clamped = stars.clamp(0, 3);
    return Semantics(
      label: 'Betyg: $clamped av 3 stjärnor',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isFilled = index < clamped;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 64.sp,
              ),
            );
          }),
        ),
      ),
    );
  }
}
