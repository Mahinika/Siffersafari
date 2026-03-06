import 'package:flutter/widgets.dart';

enum AdaptiveWindowSizeClass { compact, medium, expanded }

class AdaptiveLayoutInfo {
  const AdaptiveLayoutInfo._({
    required this.maxWidth,
    required this.maxHeight,
  });

  factory AdaptiveLayoutInfo.fromConstraints(BoxConstraints constraints) {
    return AdaptiveLayoutInfo._(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  final double maxWidth;
  final double maxHeight;

  AdaptiveWindowSizeClass get widthClass {
    if (maxWidth >= 840) return AdaptiveWindowSizeClass.expanded;
    if (maxWidth >= 600) return AdaptiveWindowSizeClass.medium;
    return AdaptiveWindowSizeClass.compact;
  }

  bool get isCompactWidth => widthClass == AdaptiveWindowSizeClass.compact;
  bool get isMediumWidth => widthClass == AdaptiveWindowSizeClass.medium;
  bool get isExpandedWidth => widthClass == AdaptiveWindowSizeClass.expanded;

  bool get isLandscape => maxWidth > maxHeight;
  bool get isShortHeight => maxHeight < 480;

  double get contentMaxWidth {
    if (isExpandedWidth) return 1100;
    if (isMediumWidth) return 900;
    return double.infinity;
  }

  int gridColumns({
    required int compact,
    int? medium,
    required int expanded,
  }) {
    if (isExpandedWidth) return expanded;
    if (isMediumWidth) return medium ?? compact;
    return compact;
  }
}