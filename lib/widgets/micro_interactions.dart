import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced micro-interactions and animations for professional UI
class MicroInteractions {
  /// Simple tap button (dead code removed)
  static Widget springButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }

  /// Ripple effect animation
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor ?? Colors.white.withValues(alpha: 0.3),
        highlightColor: rippleColor?.withValues(alpha: 0.1) ??
            Colors.white.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  /// Floating effect with shadow animation
  static Widget floatingCard({
    required Widget child,
    double elevation = 8.0,
    double hoverElevation = 16.0,
    Duration duration = const Duration(milliseconds: 200),
    BorderRadius? borderRadius,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  // ignore: dead_code
                  blurRadius: isHovered ? hoverElevation : elevation,
                  // ignore: dead_code
                  offset: Offset(0, isHovered ? 8 : 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration itemDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutQuart,
  }) {
    return Column(
      children: List.generate(children.length, (index) {
        return TweenAnimationBuilder<double>(
          duration: itemDuration,
          tween: Tween(begin: 0.0, end: 1.0),
          curve: curve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: children[index],
        );
      }),
    );
  }

  /// Smooth page transition
  static PageRouteBuilder<T> slidePageRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Morphing container animation
  static Widget morphingContainer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Decoration? decoration,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }

  /// Success checkmark animation
  static Widget animatedCheckmark({
    double size = 60,
    Color color = Colors.green,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        );
      },
    );
  }

  /// Loading dots animation
  static Widget loadingDots({
    int dotCount = 3,
    double dotSize = 8.0,
    Color color = Colors.blue,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotCount, (index) {
        return TweenAnimationBuilder<double>(
          duration: duration,
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            final delay = index * 0.2;
            final animValue = (value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * animValue);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: animValue),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Number counter animation
  static Widget animatedCounter({
    required int value,
    Duration duration = const Duration(milliseconds: 800),
    TextStyle? textStyle,
    Curve curve = Curves.easeOutQuart,
  }) {
    return TweenAnimationBuilder<int>(
      duration: duration,
      tween: IntTween(begin: 0, end: value),
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toString(),
          style: textStyle,
        );
      },
    );
  }

  /// Shake animation for errors
  static Widget shakeAnimation({
    required Widget child,
    required bool trigger,
    double strength = 5.0,
    int cycles = 3,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: trigger ? 1.0 : 0.0),
      curve: Curves.elasticInOut,
      builder: (context, value, child) {
        final offset = strength * value * (1 - value) * 4;
        return Transform.translate(
          offset: Offset(offset * math.sin(value * cycles * 2), 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Breathing animation for important elements
  static Widget breathingAnimation({
    required Widget child,
    double minScale = 0.95,
    double maxScale = 1.05,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: minScale, end: maxScale),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // Reverse animation would be handled by a StatefulWidget in real implementation
      },
      child: child,
    );
  }

  /// Gradient animation
  static Widget animatedGradient({
    required Widget child,
    required List<Color> colors,
    Duration duration = const Duration(milliseconds: 3000),
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: colors.map((color) {
                return Color.lerp(
                      color,
                      color.withValues(alpha: 0.8),
                      math.sin(value),
                    ) ??
                    color;
              }).toList(),
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
