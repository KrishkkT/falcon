import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';

/// Widget to display session status and handle timeouts
class SessionStatusWidget extends StatefulWidget {
  final Widget child;

  const SessionStatusWidget({
    super.key,
    required this.child,
  });

  @override
  State<SessionStatusWidget> createState() => _SessionStatusWidgetState();
}

class _SessionStatusWidgetState extends State<SessionStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionManager>(
      builder: (context, sessionManager, child) {
        return Stack(
          children: [
            widget.child,

            // Session timeout warning
            if (sessionManager.isSessionActive &&
                sessionManager.sessionRemainingMinutes <= 2 &&
                sessionManager.sessionRemainingMinutes > 0)
              _buildSessionWarning(sessionManager),

            // Session expired overlay
            if (!sessionManager.isSessionActive &&
                sessionManager.sessionId != null)
              _buildSessionExpiredOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildSessionWarning(SessionManager sessionManager) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.warning,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Session Timeout Warning',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Session expires in ${sessionManager.sessionRemainingMinutes} minute(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final authService =
                      Provider.of<AuthService>(context, listen: false);
                  await authService.renewSession();
                },
                child: const Text(
                  'Extend',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionExpiredOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Session Expired',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your secure session has expired for security reasons. Please log in again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Login Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to completely remove debug banners and overlays
class NoDebugWidget extends StatelessWidget {
  final Widget child;

  const NoDebugWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          child,
          // Invisible overlay to block any debug banners
          const Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 100,
              height: 50,
              child: ColoredBox(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
