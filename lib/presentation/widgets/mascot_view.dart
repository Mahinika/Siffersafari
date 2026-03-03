import 'package:flutter/material.dart';

class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    required this.asset,
    this.frames,
    this.fps = 8,
    this.height,
    this.fit = BoxFit.contain,
    this.cacheHeight,
    this.excludeFromSemantics = true,
  }) : assert(fps > 0, 'fps must be > 0');

  /// Fallback/static asset (used when [frames] is null/empty).
  final String asset;

  /// Optional frame sequence (asset paths). When provided, the mascot is
  /// animated by cycling through the frames.
  final List<String>? frames;

  /// Frames per second for the frame animation.
  final int fps;

  final double? height;
  final BoxFit fit;

  /// Forwarded to [Image.asset]. If null and [height] is provided, the widget
  /// will derive a sensible cacheHeight from the current devicePixelRatio.
  final int? cacheHeight;

  final bool excludeFromSemantics;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  List<String> get _frames {
    final frames = widget.frames;
    if (frames == null) return const [];
    return frames.where((p) => p.trim().isNotEmpty).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant MascotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fps != widget.fps || oldWidget.frames != widget.frames) {
      _syncController();
    }
  }

  void _syncController() {
    final frames = _frames;

    if (frames.length < 2) {
      _controller?.dispose();
      _controller = null;
      return;
    }

    final totalMs = ((frames.length * 1000) / widget.fps).round().clamp(1, 60000);
    final controller = _controller;
    if (controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: totalMs),
      )..repeat();
    } else {
      controller.duration = Duration(milliseconds: totalMs);
      if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheHeight = widget.cacheHeight ??
        (widget.height == null
            ? null
            : (widget.height! * MediaQuery.devicePixelRatioOf(context)).round());

    Widget buildImage(String assetPath) {
      return Image.asset(
        assetPath,
        fit: widget.fit,
        cacheHeight: cacheHeight,
        excludeFromSemantics: widget.excludeFromSemantics,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    }

    final frames = _frames;
    final controller = _controller;

    if (frames.length < 2 || controller == null) {
      return buildImage(widget.asset);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final frameIndex = (controller.value * frames.length).floor();
        final safeIndex = frameIndex.clamp(0, frames.length - 1);
        return buildImage(frames[safeIndex]);
      },
    );
  }
}
