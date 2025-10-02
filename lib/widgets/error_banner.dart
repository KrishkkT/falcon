import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorBanner extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final VoidCallback? onRetry;
  final Duration duration;

  const ErrorBanner({
    super.key,
    required this.message,
    this.backgroundColor = AppTheme.errorColor,
    this.onRetry,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();

    // Auto-hide after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            // Use Navigator.maybePop with proper error handling to prevent crashes
            try {
              Navigator.maybePop(context);
            } catch (e) {
              debugPrint('Failed to auto-hide error banner: $e');
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: widget.backgroundColor,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (widget.onRetry != null) ...[
                  TextButton(
                    onPressed: () {
                      _controller.reverse().then((_) {
                        if (mounted) {
                          widget.onRetry!();
                          // Use Navigator.maybePop with proper error handling to prevent crashes
                          try {
                            Navigator.maybePop(context);
                          } catch (e) {
                            debugPrint(
                                'Failed to pop error banner after retry: $e');
                          }
                        }
                      });
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.reverse().then((_) {
                      if (mounted) {
                        // Use Navigator.maybePop with proper error handling to prevent crashes
                        try {
                          Navigator.maybePop(context);
                        } catch (e) {
                          debugPrint('Failed to close error banner: $e');
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show error banner
void showErrorBanner(
  BuildContext context,
  String message, {
  Color backgroundColor = AppTheme.errorColor,
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 5),
}) {
  // Use maybePop with proper error handling to prevent crashes
  try {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Positioned(
          top: 100,
          left: 16,
          right: 16,
          child: ErrorBanner(
            message: message,
            backgroundColor: backgroundColor,
            onRetry: onRetry,
            duration: duration,
          ),
        );
      },
    );
  } catch (e) {
    // If we can't show a dialog, just print to console
    debugPrint('Error Banner: $message');
  }
}
