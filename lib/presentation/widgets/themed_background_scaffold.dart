import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_theme_provider.dart';

class ThemedBackgroundScaffold extends ConsumerWidget {
  const ThemedBackgroundScaffold({
    required this.body,
    this.appBar,
    this.padding,
    this.overlayOpacity = 0.72,
    this.extendBodyBehindAppBar = false,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final EdgeInsetsGeometry? padding;
  final double overlayOpacity;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appThemeConfigProvider);

    final effectiveExtendBodyBehindAppBar =
        extendBodyBehindAppBar || appBar != null;
    final appBarHeight = appBar?.preferredSize.height ?? 0.0;

    return Scaffold(
      backgroundColor: cfg.baseBackgroundColor,
      appBar: appBar,
      extendBodyBehindAppBar: effectiveExtendBodyBehindAppBar,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              cfg.backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(color: cfg.baseBackgroundColor);
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    cfg.baseBackgroundColor.withValues(alpha: overlayOpacity),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.only(
                  top: effectiveExtendBodyBehindAppBar && appBar != null
                      ? appBarHeight
                      : 0,
                ),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
