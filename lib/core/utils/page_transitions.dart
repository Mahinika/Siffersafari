import 'package:flutter/material.dart';

/// Custom page transitions for smoother navigation
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({
    required this.builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + slight slide from bottom
            const begin = Offset(0.0, 0.03);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final slideTween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );

  final WidgetBuilder builder;
}

/// Fade transition for replacement routes
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required this.builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );

  final WidgetBuilder builder;
}

/// Helper methods for navigation with smooth transitions
extension NavigationExtensions on BuildContext {
  Future<T?> pushSmooth<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SmoothPageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushReplacementSmooth<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      FadePageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushAndRemoveUntilSmooth<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate,
  ) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      FadePageRoute(builder: (_) => page),
      predicate,
    );
  }
}
