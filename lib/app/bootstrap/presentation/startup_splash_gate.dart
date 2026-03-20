import 'package:flutter/material.dart';

class StartupSplashGate extends StatefulWidget {
  const StartupSplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<StartupSplashGate> createState() => _StartupSplashGateState();
}

class _StartupSplashGateState extends State<StartupSplashGate>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 4);
  static const _switchDuration = Duration(milliseconds: 650);
  static const _handoffSplit = 0.48;
  late final bool _isWidgetTest;

  late final AnimationController _controller;
  late final Animation<double> _splashOpacity;

  late final Animation<double> _studioOpacity;
  late final Animation<double> _studioScale;
  late final Animation<Offset> _studioSlide;

  late final Animation<double> _appOpacity;
  late final Animation<double> _appScale;
  late final Animation<Offset> _appSlide;
  late final Animation<double> _appOutroOpacity;

  var _showSplash = true;
  var _didPrecache = false;

  @override
  void initState() {
    super.initState();

    _isWidgetTest = _detectWidgetTest();

    if (_isWidgetTest) {
      _showSplash = false;
      _controller = AnimationController(vsync: this, duration: Duration.zero);
      _splashOpacity = const AlwaysStoppedAnimation<double>(0.0);
      _studioOpacity = const AlwaysStoppedAnimation<double>(0.0);
      _studioScale = const AlwaysStoppedAnimation<double>(1.0);
      _studioSlide = const AlwaysStoppedAnimation<Offset>(Offset.zero);
      _appOpacity = const AlwaysStoppedAnimation<double>(1.0);
      _appScale = const AlwaysStoppedAnimation<double>(1.0);
      _appSlide = const AlwaysStoppedAnimation<Offset>(Offset.zero);
      _appOutroOpacity = const AlwaysStoppedAnimation<double>(1.0);
      return;
    }

    // Widget tests should not spend 4 seconds in a launch animation.
    // Keep production behavior unchanged.
    final duration =
        _isWidgetTest ? const Duration(milliseconds: 1) : _duration;

    _controller = AnimationController(vsync: this, duration: duration);

    // Professional pattern: define all tweens once (not inside build) and
    // advance the animation with a single controller.
    _splashOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.94, 1.00, curve: Curves.easeInOut),
      ),
    );

    _studioOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.60, curve: Curves.easeInOut),
      ),
    );
    _studioScale = Tween<double>(begin: 0.92, end: 1.00).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.28, curve: Curves.easeOutCubic),
      ),
    );
    _studioSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.28, curve: Curves.easeOutCubic),
      ),
    );

    _appOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.76, curve: Curves.easeInOut),
      ),
    );
    _appScale = Tween<double>(begin: 0.92, end: 1.00).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.86, curve: Curves.easeOutBack),
      ),
    );
    _appSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // Softer fade-out for the app icon at the very end.
    _appOutroOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.00, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (!mounted) return;
      setState(() {
        _showSplash = false;
      });
    });

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didPrecache) return;
    _didPrecache = true;

    // Avoid image decode hitch during the splash animation.
    precacheImage(
      const AssetImage('assets/images/brand/cognifox_logo.png'),
      context,
      onError: (_, __) {},
    );
    precacheImage(
      const AssetImage('assets/images/app_icon/icon_source.png'),
      context,
      onError: (_, __) {},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWidgetTest) {
      return widget.child;
    }

    return AnimatedSwitcher(
      duration: _isWidgetTest ? Duration.zero : _switchDuration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        // Fade-through handoff: old screen fades out first, then new fades in.
        // Works for both forward (incoming) and reverse (outgoing) animations.
        final opacity = CurvedAnimation(
          parent: animation,
          curve: const Interval(
            _handoffSplit,
            1.0,
            curve: Curves.easeInOutCubic,
          ),
        );
        final scale = Tween<double>(begin: 0.995, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(
              _handoffSplit,
              1.0,
              curve: Curves.easeInOutCubic,
            ),
          ),
        );
        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: _showSplash
          ? _StartupSplashScaffold(
              key: const ValueKey('launch_splash'),
              controller: _controller,
              splashOpacity: _splashOpacity,
              studioOpacity: _studioOpacity,
              studioScale: _studioScale,
              studioSlide: _studioSlide,
              appOpacity: _appOpacity,
              appScale: _appScale,
              appSlide: _appSlide,
              appOutroOpacity: _appOutroOpacity,
            )
          : widget.child,
    );
  }

  static bool _detectWidgetTest() {
    // Avoid depending on dart-define flags; tests run with a special binding.
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgets') ||
        bindingType.contains('AutomatedTestWidgets') ||
        bindingType.contains('LiveTestWidgets') ||
        bindingType.contains('IntegrationTestWidgets');
  }
}

class _StartupSplashScaffold extends StatelessWidget {
  const _StartupSplashScaffold({
    super.key,
    required this.controller,
    required this.splashOpacity,
    required this.studioOpacity,
    required this.studioScale,
    required this.studioSlide,
    required this.appOpacity,
    required this.appScale,
    required this.appSlide,
    required this.appOutroOpacity,
  });

  final AnimationController controller;
  final Animation<double> splashOpacity;
  final Animation<double> studioOpacity;
  final Animation<double> studioScale;
  final Animation<Offset> studioSlide;
  final Animation<double> appOpacity;
  final Animation<double> appScale;
  final Animation<Offset> appSlide;
  final Animation<double> appOutroOpacity;

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final imageSize = shortestSide.clamp(180.0, 280.0);

    // Keep it simple and brand-friendly: a solid black canvas.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: splashOpacity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FadeTransition(
                  opacity: studioOpacity,
                  child: SlideTransition(
                    position: studioSlide,
                    child: ScaleTransition(
                      scale: studioScale,
                      child: RepaintBoundary(
                        child: _StudioLogo(size: imageSize),
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: appOpacity,
                  child: FadeTransition(
                    opacity: appOutroOpacity,
                    child: SlideTransition(
                      position: appSlide,
                      child: ScaleTransition(
                        scale: appScale,
                        child: RepaintBoundary(
                          child: _AppIcon(size: imageSize),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioLogo extends StatelessWidget {
  const _StudioLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final onColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Image.asset(
        'assets/images/brand/cognifox_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.auto_awesome, size: 120, color: onColor);
        },
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_icon/icon_source.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.calculate, size: 120, color: Colors.white);
      },
    );
  }
}
