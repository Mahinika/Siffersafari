import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/audio_service_provider.dart';
import 'mascot_view.dart';

/// Interactive mascot that responds to taps with animations and sounds
class InteractiveMascot extends ConsumerStatefulWidget {
  const InteractiveMascot({
    super.key,
    required this.asset,
    this.idleFrames,
    this.height = 200,
    this.onTap,
  });

  /// Fallback/static asset
  final String asset;

  /// Optional idle animation frames
  final List<String>? idleFrames;

  /// Height of the mascot
  final double height;

  /// Callback when mascot is tapped
  final VoidCallback? onTap;

  @override
  ConsumerState<InteractiveMascot> createState() => _InteractiveMascotState();
}

class _InteractiveMascotState extends ConsumerState<InteractiveMascot>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  bool _isCelebrating = false;

  // Possible celebration reactions
  static const List<String> _celebrationEmojis = [
    '🎉',
    '⭐',
    '🌟',
    '✨',
    '🎊',
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _handleMascotTap() async {
    if (_isCelebrating) return;

    widget.onTap?.call();

    setState(() => _isCelebrating = true);

    // Play celebration sound
    await ref.read(audioServiceProvider).playCelebrationSound();

    // Play celebration animation
    await _celebrationController.forward();
    await _celebrationController.reverse();

    setState(() => _isCelebrating = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleMascotTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main mascot
          AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
              final celebrationAmount = Curves.easeOutBack.transform(
                _celebrationController.value,
              );
              final bounce = _isCelebrating ? celebrationAmount : 0.0;

              return Transform.translate(
                offset: Offset(0, -widget.height * 0.08 * bounce),
                child: Transform.rotate(
                  angle: bounce * 0.08,
                  child: child,
                ),
              );
            },
            child: MascotView(
              asset: widget.asset,
              frames: widget.idleFrames,
              height: widget.height,
              fit: BoxFit.contain,
              motion: MascotMotionPreset.float,
            ),
          ),
          // Celebration emoji (animates on tap)
          if (_isCelebrating)
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                final index =
                    DateTime.now().microsecond % _celebrationEmojis.length;
                return Transform.translate(
                  offset: Offset(
                    0,
                    -50 * _celebrationController.value,
                  ),
                  child: Opacity(
                    opacity: 1 - _celebrationController.value,
                    child: Text(
                      _celebrationEmojis[index],
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
