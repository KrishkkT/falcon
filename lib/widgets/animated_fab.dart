import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedFAB extends StatefulWidget {
  final VoidCallback onNewChat;
  final VoidCallback onNewGroup;
  final VoidCallback onSecureCall;

  const AnimatedFAB({
    super.key,
    required this.onNewChat,
    required this.onNewGroup,
    required this.onSecureCall,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Secure Call Option
        _buildFabItem(
          icon: Icons.phone,
          label: 'Secure Call',
          onPressed: widget.onSecureCall,
          index: 2,
        ),

        const SizedBox(height: 16),

        // New Group Option
        _buildFabItem(
          icon: Icons.group,
          label: 'New Group',
          onPressed: widget.onNewGroup,
          index: 1,
        ),

        const SizedBox(height: 16),

        // New Chat Option
        _buildFabItem(
          icon: Icons.message,
          label: 'New Chat',
          onPressed: widget.onNewChat,
          index: 0,
        ),

        const SizedBox(height: 16),

        // Main FAB
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggle,
          backgroundColor: AppTheme.primaryColor,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * 3.14159,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFabItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double scale = _expandAnimation.value;
        final double opacity = _expandAnimation.value;
        final double offset = (1 - _expandAnimation.value) * (index + 1) * 20;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, offset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    heroTag: 'fab_item_$index',
                    onPressed: () {
                      _toggle();
                      onPressed();
                    },
                    mini: true,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
