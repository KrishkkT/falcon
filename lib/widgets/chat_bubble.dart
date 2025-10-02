import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/file_viewer_screen.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String deliveryStatus;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final VoidCallback? onRetry; // Add retry callback
  final String? tempId; // Add tempId for retry

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.deliveryStatus = 'sent',
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.onRetry, // Add retry callback
    this.tempId, // Add tempId for retry
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.isMe ? const Offset(0.5, 0) : const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Add a slight delay for incoming messages
    Future.delayed(
      widget.isMe ? Duration.zero : const Duration(milliseconds: 100),
      () {
        if (mounted) {
          _animationController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simplify animations for better performance
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment:
                  widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isMe) ...[
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.greyColor,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    child: Stack(
                      children: [
                        // Message bubble with tail
                        CustomPaint(
                          painter: ChatBubblePainter(
                            isMe: widget.isMe,
                            color:
                                widget.isMe ? AppTheme.primaryGradient : null,
                            isSelected: widget.isSelected,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth:
                                  250, // Limit width for better appearance
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: widget.isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // Handle different message types
                                if (widget.message.startsWith('[Image:')) ...[
                                  _buildImageMessage(widget.message),
                                ] else if (widget.message
                                    .startsWith('[Document:')) ...[
                                  _buildDocumentMessage(widget.message),
                                ] else ...[
                                  // Regular text message
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      color: widget.isMe
                                          ? Colors.white
                                          : AppTheme.darkColor,
                                      fontSize: 16,
                                      height: 1.3,
                                      fontWeight: widget.isMe
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(widget.timestamp),
                                      style: TextStyle(
                                        color: widget.isMe
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : AppTheme.greyColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (widget.isMe) ...[
                                      const SizedBox(width: 4),
                                      // Show retry button for failed messages
                                      if (widget.deliveryStatus == 'failed' &&
                                          widget.onRetry != null &&
                                          widget.tempId != null) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.refresh,
                                            color: AppTheme.errorColor,
                                            size: 16,
                                          ),
                                          onPressed: widget.onRetry,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      _buildDeliveryStatusIcon(),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(String message) {
    // Extract filename from message
    final filename = message.replaceAll('[Image:', '').replaceAll(']', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Handle file opening by navigating to file viewer screen
            debugPrint('Opening image file: $filename');

            // Navigate to file viewer screen
            Navigator.push(
              (this as State).context,
              MaterialPageRoute(
                builder: (context) => FileViewerScreen(
                  fileName: filename,
                  fileType: 'image',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, size: 24, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filename,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white : AppTheme.darkColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '📷 Image',
          style: TextStyle(
            color: widget.isMe
                ? Colors.white.withValues(alpha: 0.8)
                : AppTheme.greyColor,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessage(String message) {
    // Extract filename from message
    final filename = message.replaceAll('[Document:', '').replaceAll(']', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Handle file opening by navigating to file viewer screen
            debugPrint('Opening document file: $filename');

            // Navigate to file viewer screen
            Navigator.push(
              (this as State).context,
              MaterialPageRoute(
                builder: (context) => FileViewerScreen(
                  fileName: filename,
                  fileType: 'document',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description,
                    size: 24, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filename,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white : AppTheme.darkColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '📄 Document',
          style: TextStyle(
            color: widget.isMe
                ? Colors.white.withValues(alpha: 0.8)
                : AppTheme.greyColor,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.deliveryStatus) {
      case 'sending':
        // Return a small loading indicator for sending status
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        );
      case 'sent':
        iconData = Icons.check;
        iconColor = Colors.white.withValues(alpha: 0.8);
        break;
      case 'delivered':
        iconData = Icons.done_all;
        iconColor = Colors.white.withValues(alpha: 0.8);
        break;
      case 'read':
        iconData = Icons.done_all;
        iconColor = AppTheme.successColor;
        break;
      case 'failed':
        iconData = Icons.error_outline;
        iconColor = AppTheme.errorColor;
        break;
      default:
        iconData = Icons.check;
        iconColor = Colors.white.withValues(alpha: 0.8);
    }

    return Icon(
      iconData,
      size: 14,
      color: iconColor,
    );
  }

  String _formatTime(DateTime dateTime) {
    // Always use device time for consistent display
    try {
      // Convert server time to device local time
      final localTime = dateTime.toLocal();
      final now = DateTime.now().toLocal();
      final difference = now.difference(localTime);

      // If message was sent today, show time
      if (localTime.day == now.day &&
          localTime.month == now.month &&
          localTime.year == now.year) {
        final hour = localTime.hour;
        final minute = localTime.minute;
        final amPm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

        return '$displayHour:${minute.toString().padLeft(2, '0')} $amPm';
      }
      // If message was sent yesterday, show "Yesterday"
      else if (difference.inDays == 1 ||
          (difference.inDays == 0 && difference.isNegative)) {
        return 'Yesterday';
      }
      // If message was sent within the last week, show day name
      else if (difference.inDays < 7 && difference.inDays >= 0) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[localTime.weekday - 1];
      }
      // Otherwise show date
      else if (difference.inDays >= 0) {
        return '${localTime.month}/${localTime.day}';
      } else {
        // Future dates (shouldn't happen, but just in case)
        return '${localTime.month}/${localTime.day}';
      }
    } catch (e) {
      // If any error occurs, return a safe default
      debugPrint('Error formatting time: $e');
      return 'Now';
    }
  }
}

// Custom painter for chat bubble with tail
class ChatBubblePainter extends CustomPainter {
  final bool isMe;
  final LinearGradient? color;
  final bool isSelected;

  ChatBubblePainter({
    required this.isMe,
    this.color,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    if (color != null) {
      // For sent messages, use gradient
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      final gradient = LinearGradient(
        colors: color!.colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      paint.shader = gradient.createShader(rect);
    } else {
      // For received messages, use solid color
      paint.color = Colors.grey[200]!;
    }

    // Create path for bubble with tail
    final path = Path();

    if (isMe) {
      // Sent message bubble (right-aligned with tail on right)
      _drawSentBubble(path, size);
    } else {
      // Received message bubble (left-aligned with tail on left)
      _drawReceivedBubble(path, size);
    }

    canvas.drawPath(path, paint);

    // Draw selection border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppTheme.primaryColor;

      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawSentBubble(Path path, Size size) {
    final radius = 16.0;
    final tailWidth = 8.0;
    final tailHeight = 12.0;

    // Start from top-left
    path.moveTo(radius, 0);

    // Top edge
    path.lineTo(size.width - radius - tailWidth, 0);

    // Top-right corner
    path.quadraticBezierTo(
        size.width - tailWidth, 0, size.width - tailWidth, radius);

    // Right edge down to where tail starts
    path.lineTo(size.width - tailWidth, size.height - radius - tailHeight);

    // Tail
    path.lineTo(size.width, size.height - radius - tailHeight + 4);
    path.lineTo(size.width - tailWidth, size.height - radius);

    // Bottom-right corner
    path.quadraticBezierTo(size.width - tailWidth, size.height,
        size.width - tailWidth - radius, size.height);

    // Bottom edge
    path.lineTo(radius, size.height);

    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Left edge
    path.lineTo(0, radius);

    // Top-left corner
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();
  }

  void _drawReceivedBubble(Path path, Size size) {
    final radius = 16.0;
    final tailWidth = 8.0;
    final tailHeight = 12.0;

    // Start from top-left (after tail)
    path.moveTo(tailWidth, radius);

    // Top-left corner
    path.quadraticBezierTo(tailWidth, 0, tailWidth + radius, 0);

    // Top edge
    path.lineTo(size.width - radius, 0);

    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Right edge
    path.lineTo(size.width, size.height - radius);

    // Bottom-right corner
    path.quadraticBezierTo(
        size.width, size.height, size.width - radius, size.height);

    // Bottom edge
    path.lineTo(tailWidth + radius, size.height);

    // Bottom-left corner
    path.quadraticBezierTo(
        tailWidth, size.height, tailWidth, size.height - radius);

    // Left edge up to where tail starts
    path.lineTo(tailWidth, radius + tailHeight);

    // Tail
    path.lineTo(0, radius + tailHeight - 4);
    path.lineTo(tailWidth, radius);

    path.close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
