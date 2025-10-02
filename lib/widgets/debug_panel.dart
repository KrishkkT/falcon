import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../services/vpn_service.dart';
import '../services/network_config_service.dart';
import '../theme/app_theme.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool _isPinging = false;
  String _pingResult = '';
  double _pingTime = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.greyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Debug Panel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // VPN Status and Toggle
          _buildVpnSection(),

          const SizedBox(height: 16),

          // Network Configuration
          _buildNetworkConfigSection(),

          const SizedBox(height: 16),

          // Backend Ping
          _buildPingSection(),
        ],
      ),
    );
  }

  Widget _buildVpnSection() {
    return Consumer<VpnService>(
      builder: (context, vpnService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VPN Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: vpnService.isConnected
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  vpnService.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: vpnService.isConnected
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed:
                      vpnService.isConnecting ? null : vpnService.toggleVpn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vpnService.isConnected
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      Text(vpnService.isConnected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
            if (vpnService.isConnecting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkConfigSection() {
    final serverIp = NetworkConfigService.getCurrentServerIp();
    final serverPort = 3001; // Default port
    final baseUrl = NetworkConfigService.getBaseApiUrl();
    final wsUrl = NetworkConfigService.getWebSocketUrl();
    final isVpnActive = NetworkConfigService.isVpnActive();
    final isForceVpnLocal = NetworkConfigService.isForceVpnLocal();
    final isProduction = NetworkConfigService.isProduction();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Network Configuration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildConfigRow('Server IP', serverIp),
        _buildConfigRow('Base URL', baseUrl),
        _buildConfigRow('WebSocket URL', wsUrl),
        _buildConfigRow('VPN Active', isVpnActive.toString()),
        _buildConfigRow('Force VPN Local', isForceVpnLocal.toString()),
        _buildConfigRow('Production Mode', isProduction.toString()),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backend Ping',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _isPinging ? null : _pingBackend,
              child: Text(_isPinging ? 'Pinging...' : 'Ping Backend'),
            ),
            const SizedBox(width: 16),
            if (_pingResult.isNotEmpty)
              Expanded(
                child: Text(
                  _pingResult,
                  style: TextStyle(
                    color: _pingResult.contains('Success')
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        if (_pingTime > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Response time: ${_pingTime.toStringAsFixed(2)} ms',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pingBackend() async {
    setState(() {
      _isPinging = true;
      _pingResult = '';
      _pingTime = 0.0;
    });

    try {
      final baseUrl = NetworkConfigService.getBaseApiUrl();
      final uri =
          Uri.parse('$baseUrl/ping'); // Assuming there's a /ping endpoint

      final stopwatch = Stopwatch()..start();
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      stopwatch.stop();

      setState(() {
        _pingTime = stopwatch.elapsedMilliseconds.toDouble();
        if (response.statusCode == 200) {
          _pingResult = 'Success: ${response.body}';
        } else {
          _pingResult =
              'Error: ${response.statusCode} ${response.reasonPhrase}';
        }
        _isPinging = false;
      });
    } on SocketException catch (e) {
      setState(() {
        _pingResult = 'Network Error: ${e.message}';
        _isPinging = false;
      });
    } catch (e) {
      setState(() {
        _pingResult = 'Error: ${e.toString()}';
        _isPinging = false;
      });
    }
  }
}
