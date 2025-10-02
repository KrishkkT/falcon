import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:provider/provider.dart';

import '../services/network_config_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class NetworkSetupScreen extends StatefulWidget {
  const NetworkSetupScreen({super.key});

  @override
  State<NetworkSetupScreen> createState() => _NetworkSetupScreenState();
}

class _NetworkSetupScreenState extends State<NetworkSetupScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  bool _useDomain = false; // Flag to toggle between IP and domain input
  bool _isTesting = false;
  String _testResult = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current IP if available
    _ipController.text = NetworkConfigService.getCurrentServerIp();
    _portController.text = '3001';
    _domainController.text = NetworkConfigService.getServerDomain();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection...';
      _isConnected = false;
    });

    try {
      String testUrl;

      if (_useDomain) {
        final domain = _domainController.text.trim();
        if (domain.isEmpty) {
          setState(() {
            _isTesting = false;
            _testResult = 'Please enter a valid domain name';
          });
          return;
        }
        testUrl = 'https://$domain/api';
      } else {
        final ip = _ipController.text.trim();
        final port = _portController.text.trim();

        if (ip.isEmpty) {
          setState(() {
            _isTesting = false;
            _testResult = 'Please enter a valid IP address';
          });
          return;
        }

        // Validate IP format
        if (!_isValidIp(ip)) {
          setState(() {
            _isTesting = false;
            _testResult =
                'Please enter a valid IP address (e.g., 192.168.1.100)';
          });
          return;
        }

        testUrl = 'http://$ip:$port/api';
      }

      final isConnected =
          await NetworkConfigService.testServerConnection(testUrl);

      if (isConnected) {
        setState(() {
          _isTesting = false;
          _testResult = 'Connection successful!';
          _isConnected = true;
        });
      } else {
        setState(() {
          _isTesting = false;
          _testResult =
              'Connection failed. Please check IP/domain and ensure server is running.';
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = 'Connection error: ${e.toString()}';
        _isConnected = false;
      });
    }
  }

  bool _isValidIp(String ip) {
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  Future<void> _saveAndContinue() async {
    if (!_isConnected) {
      // Test connection first if not already tested
      await _testConnection();

      if (!_isConnected) {
        // If still not connected, show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please test and establish a successful connection first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Update network configuration based on whether using domain or IP
    if (_useDomain) {
      final domain = _domainController.text.trim();
      NetworkConfigService.updateForDomain(domain);
    } else {
      final ip = _ipController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 3001;
      NetworkConfigService.updateForRealDevice(ip, port);
    }

    // Update service URLs
    final baseUrl = NetworkConfigService.getBaseApiUrl();
    final wsUrl = NetworkConfigService.getWebSocketUrl();

    ChatService.updateBaseUrls(baseUrl, wsUrl);
    AuthService.updateBaseUrl(baseUrl);

    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                const Text(
                  'Network Setup',
                  style: AppTheme.headingStyle,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Configure your server connection for real device usage',
                  style: AppTheme.captionStyle,
                ),

                const SizedBox(height: 20),

                // Toggle between IP and Domain
                Row(
                  children: [
                    const Text(
                      'Use Domain:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: _useDomain,
                      onChanged: (value) {
                        setState(() {
                          _useDomain = value;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Show either domain input or IP/port inputs based on toggle
                if (_useDomain) ...[
                  // Domain Input
                  const Text(
                    'Server Domain',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _domainController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'e.g., yourdomain.com',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide(
                          color: AppTheme.greyColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // IP Address Input
                  const Text(
                    'Server IP Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'e.g., 192.168.1.100',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide(
                          color: AppTheme.greyColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Port Input
                  const Text(
                    'Server Port',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: 'e.g., 3001',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide(
                          color: AppTheme.greyColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Test Connection Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppTheme.mediumRadius,
                      ),
                    ),
                    child: _isTesting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Testing Connection...'),
                            ],
                          )
                        : const Text('Test Connection'),
                  ),
                ),

                const SizedBox(height: 10),

                // Test Result
                if (_testResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: AppTheme.smallRadius,
                      border: Border.all(
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _testResult,
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: AppTheme.mediumRadius,
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Setup Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_useDomain) ...[
                        const Text(
                          '1. Ensure your domain points to your server IP',
                          style: AppTheme.captionStyle,
                        ),
                        const Text(
                          '2. Configure SSL certificates for your domain',
                          style: AppTheme.captionStyle,
                        ),
                        const Text(
                          '3. Enter your domain name above and test the connection',
                          style: AppTheme.captionStyle,
                        ),
                      ] else ...[
                        const Text(
                          '1. Ensure your backend server is running on your computer',
                          style: AppTheme.captionStyle,
                        ),
                        const Text(
                          '2. Find your computer\'s local IP address (e.g., 192.168.1.100)',
                          style: AppTheme.captionStyle,
                        ),
                        const Text(
                          '3. Make sure your phone and computer are on the same WiFi network',
                          style: AppTheme.captionStyle,
                        ),
                        const Text(
                          '4. Enter the IP address above and test the connection',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Save and Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConnected ? _saveAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isConnected ? AppTheme.primaryColor : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppTheme.mediumRadius,
                      ),
                    ),
                    child: const Text('Save and Continue'),
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
