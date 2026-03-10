import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

enum VilleReaction {
  idle,
  enter,
  answerCorrect,
  answerWrong,
  celebrate,
  userTap,
  screenChange,
}

class VilleCharacter extends StatefulWidget {
  const VilleCharacter({
    super.key,
    this.reaction = VilleReaction.idle,
    this.reactionNonce = 0,
    this.height = 96,
    this.fit = BoxFit.contain,
    this.riveAssetPath = 'assets/characters/ville/rive/ville_character.riv',
    this.stateMachineName = 'VilleStateMachine',
  });

  final VilleReaction reaction;
  final int reactionNonce;
  final double height;
  final BoxFit fit;
  final String riveAssetPath;
  final String stateMachineName;

  @override
  State<VilleCharacter> createState() => _VilleCharacterState();
}

class _VilleCharacterState extends State<VilleCharacter> {
  Artboard? _artboard;
  SMITrigger? _answerCorrect;
  SMITrigger? _answerWrong;
  SMITrigger? _userTap;
  SMITrigger? _screenChange;

  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  @override
  void didUpdateWidget(covariant VilleCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reactionNonce != oldWidget.reactionNonce ||
        widget.reaction != oldWidget.reaction) {
      _fireReaction(widget.reaction);
    }
  }

  Future<void> _loadRive() async {
    try {
      final data = await RiveFile.asset(widget.riveAssetPath);
      final artboard = data.mainArtboard;
      final controller = StateMachineController.fromArtboard(
        artboard,
        widget.stateMachineName,
      );

      if (controller != null) {
        artboard.addController(controller);
        _answerCorrect =
            controller.findInput<bool>('answer_correct') as SMITrigger?;
        _answerWrong = controller.findInput<bool>('answer_wrong') as SMITrigger?;
        _userTap = controller.findInput<bool>('user_tap') as SMITrigger?;
        _screenChange = controller.findInput<bool>('screen_change') as SMITrigger?;
      }

      if (!mounted) return;
      setState(() {
        _artboard = artboard;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
      });
    }
  }

  void _fireReaction(VilleReaction reaction) {
    switch (reaction) {
      case VilleReaction.idle:
        break;
      case VilleReaction.enter:
        _userTap?.fire();
      case VilleReaction.answerCorrect:
        _answerCorrect?.fire();
      case VilleReaction.answerWrong:
        _answerWrong?.fire();
      case VilleReaction.celebrate:
        _answerCorrect?.fire();
      case VilleReaction.userTap:
        _userTap?.fire();
      case VilleReaction.screenChange:
        _screenChange?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed || _artboard == null) {
      return _fallback(context);
    }

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onTap: () {
          _userTap?.fire();
        },
        child: Rive(
          artboard: _artboard!,
          fit: widget.fit,
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    // Show composite SVG as fallback when Rive file is not available
    return SizedBox(
      height: widget.height,
      child: SvgPicture.asset(
        'assets/characters/ville/svg/ville_composite.svg',
        fit: widget.fit,
        placeholderBuilder: (context) => _iconFallback(context),
      ),
    );
  }

  Widget _iconFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
      ),
    );
  }
}
