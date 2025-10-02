import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/auth_service.dart';
import '../services/vpn_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _biometricEnabled = false;
  bool _autoDeleteEnabled = true;
  bool _screenshotBlocked = true;
  bool _forwardProtection = true;
  bool _endToEndEncryption = true;
  int _autoDeleteDays = 30;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    // Load user settings from secure storage
    // This would be connected to your backend/local storage
    setState(() {
      // Default secure settings for Ministry of Defense
      _biometricEnabled = true;
      _autoDeleteEnabled = true;
      _screenshotBlocked = true;
      _forwardProtection = true;
      _endToEndEncryption = true;
      _autoDeleteDays = 7; // Change default to 7 days
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProfileHeader() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return AnimatedWidgets.slideInContainer(
      index: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: AppTheme.largeRadius,
          boxShadow: AppTheme.strongShadow,
        ),
        child: Column(
          children: [
            // Profile Picture
            Hero(
              tag: 'profile_picture',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              user?['name'] ?? 'Defense User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // User Mobile
            Text(
              user?['mobile'] ?? '+1234567890',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),

            // Security Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: AppTheme.mediumRadius,
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'MILITARY GRADE SECURITY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVpnStatus() {
    return Consumer<VpnService>(
      builder: (context, vpnService, child) {
        return AnimatedWidgets.slideInContainer(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.largeRadius,
              boxShadow: AppTheme.mediumShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.vpn_lock,
                      color:
                          vpnService.isConnected ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VPN Security Tunnel',
                            style: AppTheme.subHeadingStyle,
                          ),
                          Text(
                            vpnService.isConnected
                                ? 'SECURE CONNECTION ACTIVE'
                                : 'DISCONNECTED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: vpnService.isConnected
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: vpnService.isConnected,
                      onChanged: (value) {
                        if (value) {
                          vpnService.startVpn();
                        } else {
                          vpnService.stopVpn();
                        }
                      },
                      activeTrackColor: Colors.green,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // VPN Details
                if (vpnService.isConnected) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow('Protocol', 'WireGuard (Military Grade)'),
                  _buildInfoRow('Encryption', 'ChaCha20-Poly1305'),
                  _buildInfoRow('Server Location', 'Secure Government Node'),
                  _buildInfoRow('IP Protection', 'Anonymous Routing'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecuritySettings() {
    return AnimatedWidgets.slideInContainer(
      index: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.largeRadius,
          boxShadow: AppTheme.mediumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Security Settings',
                  style: AppTheme.subHeadingStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSecurityToggle(
              'Biometric Authentication',
              'Use fingerprint/face unlock',
              _biometricEnabled,
              (value) => setState(() => _biometricEnabled = value),
              Icons.fingerprint,
            ),
            _buildSecurityToggle(
              'End-to-End Encryption',
              'AES-256-GCM encryption for all messages',
              _endToEndEncryption,
              (value) => setState(() => _endToEndEncryption = value),
              Icons.lock,
            ),
            _buildSecurityToggle(
              'Screenshot Protection',
              'Block screenshots and screen recording',
              _screenshotBlocked,
              (value) => setState(() => _screenshotBlocked = value),
              Icons.screenshot_monitor,
            ),
            _buildSecurityToggle(
              'Forward Protection',
              'Prevent message forwarding',
              _forwardProtection,
              (value) => setState(() => _forwardProtection = value),
              Icons.forward,
            ),
            _buildSecurityToggle(
              'Auto-Delete Messages',
              'Automatically delete messages after $_autoDeleteDays days',
              _autoDeleteEnabled,
              (value) => setState(() => _autoDeleteEnabled = value),
              Icons.delete_forever,
            ),
            if (_autoDeleteEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Auto-delete period: '),
                  Expanded(
                    child: Slider(
                      value: _autoDeleteDays.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      label: '$_autoDeleteDays days',
                      onChanged: (value) {
                        setState(() => _autoDeleteDays = value.round());
                      },
                    ),
                  ),
                  Text('$_autoDeleteDays days'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.green,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return AnimatedWidgets.slideInContainer(
      index: 3,
      child: Column(
        children: [
          // Security Audit
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: AnimatedWidgets.gradientButton(
              text: 'View Security Audit Logs',
              onPressed: _showSecurityAuditLogs,
              icon: Icons.analytics,
            ),
          ),

          // Export Logs
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: _exportSecurityLogs,
              icon: const Icon(Icons.download),
              label: const Text('Export Security Logs'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Secure Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityAuditLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: const Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Security Audit Logs',
                    style: AppTheme.headingStyle,
                  ),
                ],
              ),
            ),

            // Logs List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 10, // Sample logs
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: AppTheme.mediumRadius,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'VPN Connection Established',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Secure tunnel activated with military-grade encryption',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today 10:${30 + index}:00 AM',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportSecurityLogs() {
    // Implementation for exporting security logs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security logs exported to secure storage'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Secure Logout'),
          ],
        ),
        content: const Text(
          'This will securely wipe all local data and disconnect VPN. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Secure logout process
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final vpnService =
                  Provider.of<VpnService>(context, listen: false);

              // Disconnect VPN
              await vpnService.stopVpn();

              // Clear secure storage
              await authService.logout();

              // Navigate to login
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile & Security',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildVpnStatus(),
                    const SizedBox(height: 24),
                    _buildSecuritySettings(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
