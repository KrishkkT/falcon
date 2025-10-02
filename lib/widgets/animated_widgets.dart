import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart'; // Add Lottie import
import '../theme/app_theme.dart';

/// Collection of beautiful animated widgets for Falcon app
class AnimatedWidgets {
  /// Animated slide-in container with fade effect
  static Widget slideInContainer({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = const Duration(milliseconds: 600),
    Offset beginOffset = const Offset(0, 50),
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      delay: delay,
      child: SlideAnimation(
        verticalOffset: beginOffset.dy,
        horizontalOffset: beginOffset.dx,
        duration: duration,
        child: FadeInAnimation(
          duration: duration,
          child: child,
        ),
      ),
    );
  }

  /// Animated scale-in container
  static Widget scaleInContainer({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      delay: delay,
      child: ScaleAnimation(
        duration: duration,
        child: FadeInAnimation(
          duration: duration,
          child: child,
        ),
      ),
    );
  }

  /// Animated gradient button with ripple effect
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    LinearGradient gradient = AppTheme.primaryGradient,
    double? width,
    double height = 56,
    bool loading = false,
    IconData? icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: AppTheme.mediumRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTheme.buttonStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Animated input field with floating label
  static Widget animatedTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    Widget? prefixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  /// Animated card with hover effect
  static Widget animatedCard({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    VoidCallback? onTap,
    double elevation = 4,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Card(
            margin: margin ?? const EdgeInsets.all(8),
            elevation: elevation,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppTheme.mediumRadius,
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Animated floating action button with pulse effect
  static Widget pulseFAB({
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    bool isPulsing = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 1.0, end: isPulsing ? 1.1 : 1.0),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            heroTag: 'animated_fab',
            onPressed: onPressed,
            backgroundColor: backgroundColor ?? AppTheme.primaryColor,
            child: Icon(icon, color: Colors.white),
          ),
        );
      },
    );
  }

  /// Animated list item with slide and fade
  static Widget animatedListItem({
    required Widget child,
    required int index,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      delay: const Duration(milliseconds: 50),
      child: SlideAnimation(
        verticalOffset: 30,
        child: FadeInAnimation(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Animated progress indicator with gradient
  static Widget gradientProgressIndicator({
    required double progress,
    LinearGradient gradient = AppTheme.primaryGradient,
    double height = 4,
    Color backgroundColor = const Color(0xFFE0E0E0),
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }

  /// Animated loading indicator with custom animation
  static Widget loadingIndicator({
    String? message,
    Color color = AppTheme.primaryColor,
    double size = 50,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Animated success checkmark
  static Widget successCheckmark({
    double size = 100,
    Color color = AppTheme.successColor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
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
                  offset: const Offset(0, 10),
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

  /// Animated message bubble with typing indicator
  static Widget typingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  margin: EdgeInsets.only(
                    right: i < 2 ? 4 : 0,
                    top: (1 - value) * 8,
                  ),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Animated connection status indicator
  static Widget connectionStatus({
    required bool isConnected,
    String connectedText = 'Connected',
    String disconnectedText = 'Disconnected',
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? AppTheme.successColor : AppTheme.errorColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? connectedText : disconnectedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Animated shimmer loading effect
  static Widget shimmerLoading({
    required Widget child,
    bool isLoading = true,
  }) {
    if (!isLoading) return child;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: -1.0, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + value, 0.0),
              end: Alignment(1.0 + value, 0.0),
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: Container(
            color: Colors.grey[300],
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Animated switcher with custom transition
  static Widget animatedSwitcher({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve switchInCurve = Curves.easeOut,
    Curve switchOutCurve = Curves.easeIn,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Hero transition wrapper
  static Widget hero({
    required Widget child,
    required Object tag,
    CreateRectTween? createRectTween,
  }) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween,
      child: child,
    );
  }

  /// Lottie animation wrapper with optimization
  static Widget lottieAnimation({
    required String assetName,
    double width = 100,
    double height = 100,
    bool repeat = true,
    bool reverse = false,
    Duration? duration,
    double? frameRate,
  }) {
    return Lottie.asset(
      assetName,
      width: width,
      height: height,
      repeat: repeat,
      reverse: reverse,
      frameRate: frameRate != null ? FrameRate(frameRate) : null,
      fit: BoxFit.contain,
    );
  }

  /// Animated fade transition
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Animated slide transition
  static Widget slideTransition({
    required Widget child,
    required Animation<Offset> animation,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Animated rotation transition
  static Widget rotationTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }
}
