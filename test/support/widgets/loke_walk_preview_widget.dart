import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LokeWalkPreviewWidget extends StatefulWidget {
  const LokeWalkPreviewWidget({
    super.key,
    this.height = 140,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  State<LokeWalkPreviewWidget> createState() => _LokeWalkPreviewWidgetState();
}

class _LokeWalkPreviewWidgetState extends State<LokeWalkPreviewWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * 0.68;

    return SizedBox(
      height: widget.height,
      width: width,
      child: FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: 400,
          height: 600,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final cycle = _controller.value * math.pi * 2;
              final swing = math.sin(cycle);
              final oppositeSwing = math.sin(cycle + math.pi);
              final double bodyBob = math.sin(cycle * 2) * 6;
              final double headBob = math.sin(cycle * 2) * 3;
              final double bodyTilt = swing * 0.02;
              final double leftUpperArmAngle = oppositeSwing * 0.22 + 0.06;
              final double rightUpperArmAngle = swing * 0.22 - 0.06;
              final double leftLowerArmAngle = math.max(0, swing) * 0.28 - 0.06;
              final double rightLowerArmAngle =
                  math.max(0, oppositeSwing) * 0.28 - 0.06;
              final double leftUpperLegAngle = swing * 0.18 - 0.04;
              final double rightUpperLegAngle = oppositeSwing * 0.18 + 0.04;
              final double leftLowerLegAngle =
                  math.max(0, oppositeSwing) * 0.20;
              final double rightLowerLegAngle = math.max(0, swing) * 0.20;
              final bool blink =
                  _controller.value > 0.78 && _controller.value < 0.86;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _positioned(
                    left: 70,
                    top: 510,
                    width: 260,
                    height: 80,
                    child: Transform.scale(
                      scaleX: 1 - (bodyBob.abs() / 40),
                      scaleY: 1 - (bodyBob.abs() / 70),
                      child: _svg('assets/characters/loke/svg/loke_shadow.svg'),
                    ),
                  ),
                  _positioned(
                    left: 70,
                    top: 142 + bodyBob * 0.25,
                    width: 260,
                    height: 260,
                    child: Transform.rotate(
                      angle: oppositeSwing * 0.03,
                      alignment: Alignment.topCenter,
                      child:
                          _svg('assets/characters/loke/svg/loke_backpack.svg'),
                    ),
                  ),
                  _positioned(
                    left: 126,
                    top: 318 + bodyBob,
                    width: 102,
                    height: 250,
                    child: _buildSegmentedLeg(
                      upperAsset:
                          'assets/characters/loke/svg/loke_leg_upper_left.svg',
                      lowerAsset:
                          'assets/characters/loke/svg/loke_leg_lower_left.svg',
                      upperAngle: leftUpperLegAngle,
                      lowerAngle: leftLowerLegAngle,
                    ),
                  ),
                  _positioned(
                    left: 182,
                    top: 318 + bodyBob,
                    width: 102,
                    height: 250,
                    child: _buildSegmentedLeg(
                      upperAsset:
                          'assets/characters/loke/svg/loke_leg_upper_right.svg',
                      lowerAsset:
                          'assets/characters/loke/svg/loke_leg_lower_right.svg',
                      upperAngle: rightUpperLegAngle,
                      lowerAngle: rightLowerLegAngle,
                    ),
                  ),
                  _positioned(
                    left: 118,
                    top: 486 + bodyBob,
                    width: 132,
                    height: 92,
                    child: Transform.rotate(
                      angle:
                          leftUpperLegAngle + leftLowerLegAngle + swing * 0.08,
                      alignment: Alignment.topCenter,
                      child:
                          _svg('assets/characters/loke/svg/loke_shoe_left.svg'),
                    ),
                  ),
                  _positioned(
                    left: 166,
                    top: 486 + bodyBob,
                    width: 132,
                    height: 92,
                    child: Transform.rotate(
                      angle: rightUpperLegAngle +
                          rightLowerLegAngle +
                          oppositeSwing * 0.08,
                      alignment: Alignment.topCenter,
                      child: _svg(
                        'assets/characters/loke/svg/loke_shoe_right.svg',
                      ),
                    ),
                  ),
                  _positioned(
                    left: 60,
                    top: 170 + bodyBob,
                    width: 280,
                    height: 300,
                    child: Transform.rotate(
                      angle: bodyTilt,
                      alignment: Alignment.bottomCenter,
                      child: _svg('assets/characters/loke/svg/loke_torso.svg'),
                    ),
                  ),
                  _positioned(
                    left: 98,
                    top: 194 + bodyBob,
                    width: 96,
                    height: 246,
                    child: _buildSegmentedArm(
                      upperAsset:
                          'assets/characters/loke/svg/loke_arm_upper_left.svg',
                      lowerAsset:
                          'assets/characters/loke/svg/loke_arm_lower_left.svg',
                      upperAngle: leftUpperArmAngle,
                      lowerAngle: leftLowerArmAngle,
                    ),
                  ),
                  _positioned(
                    left: 208,
                    top: 194 + bodyBob,
                    width: 96,
                    height: 246,
                    child: _buildSegmentedArm(
                      upperAsset:
                          'assets/characters/loke/svg/loke_arm_upper_right.svg',
                      lowerAsset:
                          'assets/characters/loke/svg/loke_arm_lower_right.svg',
                      upperAngle: rightUpperArmAngle,
                      lowerAngle: rightLowerArmAngle,
                    ),
                  ),
                  _positioned(
                    left: 70,
                    top: 48 + bodyBob * 0.8,
                    width: 260,
                    height: 240,
                    child: Transform.translate(
                      offset: Offset(0, headBob),
                      child: Transform.rotate(
                        angle: oppositeSwing * 0.035,
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: _svg(
                                'assets/characters/loke/svg/loke_head.svg',
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              width: 260,
                              height: 140,
                              child: _svg(
                                blink
                                    ? 'assets/characters/loke/svg/loke_eyes_blink.svg'
                                    : 'assets/characters/loke/svg/loke_eyes_open.svg',
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 78,
                              width: 260,
                              height: 120,
                              child: _svg(
                                'assets/characters/loke/svg/loke_mouth_happy.svg',
                              ),
                            ),
                            Positioned(
                              left: -30,
                              top: -32,
                              width: 320,
                              height: 180,
                              child: Transform.rotate(
                                angle: swing * 0.025,
                                alignment: Alignment.bottomCenter,
                                child: _svg(
                                  'assets/characters/loke/svg/loke_hat.svg',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _positioned({
    required double left,
    required double top,
    required double width,
    required double height,
    required Widget child,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _svg(String asset) {
    return SvgPicture.asset(asset, fit: BoxFit.contain);
  }

  Widget _buildSegmentedArm({
    required String upperAsset,
    required String lowerAsset,
    required double upperAngle,
    required double lowerAngle,
  }) {
    return Transform.rotate(
      angle: upperAngle,
      alignment: Alignment.topCenter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 12,
            top: 0,
            width: 72,
            height: 132,
            child: _svg(upperAsset),
          ),
          Positioned(
            left: 6,
            top: 102,
            width: 84,
            height: 148,
            child: Transform.rotate(
              angle: lowerAngle,
              alignment: Alignment.topCenter,
              child: _svg(lowerAsset),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedLeg({
    required String upperAsset,
    required String lowerAsset,
    required double upperAngle,
    required double lowerAngle,
  }) {
    return Transform.rotate(
      angle: upperAngle,
      alignment: Alignment.topCenter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            top: 0,
            width: 80,
            height: 132,
            child: _svg(upperAsset),
          ),
          Positioned(
            left: 16,
            top: 102,
            width: 72,
            height: 138,
            child: Transform.rotate(
              angle: lowerAngle,
              alignment: Alignment.topCenter,
              child: _svg(lowerAsset),
            ),
          ),
        ],
      ),
    );
  }
}
