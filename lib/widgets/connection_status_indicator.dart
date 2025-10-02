import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
// import '../theme/app_theme.dart';

/// Widget to display connection status with user-friendly messages
class ConnectionStatusIndicator extends StatefulWidget {
  final Widget child;

  const ConnectionStatusIndicator({
    super.key,
    required this.child,
  });

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with TickerProviderStateMixin {
  bool _showConnectionStatus = false;
  String _connectionMessage = '';
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.cloud_off;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _showConnectionStatus = false;
    _connectionMessage = '';
    _statusColor = Colors.grey;
    _statusIcon = Icons.cloud_off;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start above the screen
      end: Offset.zero, // End at original position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        // Determine status values without calling setState
        bool showStatus = _showConnectionStatus;
        String message = _connectionMessage;
        Color color = _statusColor;
        IconData icon = _statusIcon;

        // Update status values
        if (chatService.isConnecting) {
          showStatus = true;
          message =
              chatService.isConnected ? 'Reconnecting...' : 'Connecting...';
          color = Colors.orange;
          icon = Icons.cloud_upload;
        } else if (!chatService.isConnected) {
          showStatus = true;
          message = 'No Internet';
          color = Colors.red;
          icon = Icons.cloud_off;
        } else {
          // Connected
          message = 'Connected';
          color = Colors.green;
          icon = Icons.cloud_done;

          // Hide after 2 seconds when connected
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showConnectionStatus = false;
              });
              _animationController.reverse();
            }
          });
        }

        return Stack(
          children: [
            widget.child,

            // Connection status indicator
            if (showStatus)
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child:
                        _buildConnectionStatusIndicator(message, color, icon),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatusIndicator(
      String message, Color color, IconData icon) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: color,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (message == 'Connecting...' || message == 'Reconnecting...')
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
