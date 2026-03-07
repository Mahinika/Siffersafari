import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MascotMotionPreset {
  none,
  float,
  bounce,
}

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
    this.motion = MascotMotionPreset.none,
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

  final MascotMotionPreset motion;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  AnimationController? _controller;
  AnimationController? _motionController;

  List<String> get _frames {
    final frames = widget.frames;
    if (frames == null) return const [];
    return frames.where((p) => p.trim().isNotEmpty).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _syncController();
    _syncMotionController();
  }

  @override
  void didUpdateWidget(covariant MascotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fps != widget.fps || oldWidget.frames != widget.frames) {
      _syncController();
    }
    if (oldWidget.motion != widget.motion) {
      _syncMotionController();
    }
  }

  void _syncController() {
    final frames = _frames;

    if (frames.length < 2) {
      _controller?.dispose();
      _controller = null;
      return;
    }

    final totalMs =
        ((frames.length * 1000) / widget.fps).round().clamp(1, 60000);
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

  void _syncMotionController() {
    if (widget.motion == MascotMotionPreset.none) {
      _motionController?.dispose();
      _motionController = null;
      return;
    }

    final duration = switch (widget.motion) {
      MascotMotionPreset.none => const Duration(milliseconds: 1600),
      MascotMotionPreset.float => const Duration(milliseconds: 2200),
      MascotMotionPreset.bounce => const Duration(milliseconds: 1200),
    };

    final controller = _motionController;
    if (controller == null) {
      _motionController = AnimationController(vsync: this, duration: duration)
        ..repeat();
    } else {
      controller.duration = duration;
      if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _motionController?.dispose();
    super.dispose();
  }

  Widget _applyMotion(Widget child) {
    final motionController = _motionController;
    if (motionController == null || widget.motion == MascotMotionPreset.none) {
      return child;
    }

    final mascotHeight = widget.height ?? 160;
    final verticalAmplitude = (mascotHeight * 0.035).clamp(2.0, 8.0);

    return AnimatedBuilder(
      animation: motionController,
      child: child,
      builder: (context, child) {
        final t = motionController.value;
        final wave =
            Curves.easeInOut.transform((1 - (2 * t - 1).abs()).clamp(0.0, 1.0));

        return switch (widget.motion) {
          MascotMotionPreset.none => child!,
          MascotMotionPreset.float => Transform.translate(
              offset: Offset(
                0,
                -verticalAmplitude * (0.5 + 0.5 * math.sin(t * math.pi * 2)),
              ),
              child: Transform.rotate(
                angle: math.sin(t * math.pi * 2) * 0.03,
                child: child,
              ),
            ),
          MascotMotionPreset.bounce => Transform.translate(
              offset: Offset(0, -verticalAmplitude * 1.4 * wave),
              child: Transform.scale(
                scaleX: 1 + 0.02 * wave,
                scaleY: 1 - 0.035 * wave,
                child: child,
              ),
            ),
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheHeight = widget.cacheHeight ??
        (widget.height == null
            ? null
            : (widget.height! * MediaQuery.devicePixelRatioOf(context))
                .round());

    Widget buildImage(String assetPath, {required bool isFrame}) {
      return Image.asset(
        assetPath,
        fit: widget.fit,
        cacheHeight: cacheHeight,
        excludeFromSemantics: widget.excludeFromSemantics,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          if (!isFrame) return const SizedBox.shrink();
          return buildImage(widget.asset, isFrame: false);
        },
      );
    }

    final frames = _frames;
    final controller = _controller;

    if (frames.length < 2 || controller == null) {
      return _applyMotion(buildImage(widget.asset, isFrame: false));
    }

    final animatedImage = AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final frameIndex = (controller.value * frames.length).floor();
        final safeIndex = frameIndex.clamp(0, frames.length - 1);
        return buildImage(frames[safeIndex], isFrame: true);
      },
    );

    return _applyMotion(animatedImage);
  }
}
