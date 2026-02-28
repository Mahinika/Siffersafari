import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_theme_provider.dart';

class ThemedBackgroundScaffold extends ConsumerWidget {
  const ThemedBackgroundScaffold({
    required this.body,
    this.appBar,
    this.padding,
    this.overlayOpacity = 0.76,
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

    return Scaffold(
      backgroundColor: cfg.baseBackgroundColor,
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              cfg.backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/splash_background.png',
                  fit: BoxFit.cover,
                );
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
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
