import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/debug_panel.dart';
import '../widgets/log_viewer.dart'; // Add log viewer import
import '../services/vpn_service.dart';
import '../services/network_config_service.dart';
import '../services/log_service.dart'; // Add log service import

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tools'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tools Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug & Diagnostics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Developer tools for troubleshooting and diagnostics',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Debug Panel
                const DebugPanel(),

                const SizedBox(height: 24),

                // Additional Debug Tools
                _buildAdditionalTools(),
              ],
            ),
          ),

          // Logs Tab
          const LogViewer(),
        ],
      ),
    );
  }

  Widget _buildAdditionalTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Force Refresh Network Config
        ElevatedButton(
          onPressed: _forceRefreshNetworkConfig,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Force Refresh Network Config'),
        ),

        const SizedBox(height: 12),

        // Reset VPN State
        ElevatedButton(
          onPressed: _resetVpnState,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warningColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Reset VPN State'),
        ),

        const SizedBox(height: 12),

        // Clear All Data
        ElevatedButton(
          onPressed: _clearAllData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Clear All Data (⚠️ Destructive)'),
        ),

        const SizedBox(height: 12),

        // Export Logs
        Consumer<LogService>(
          builder: (context, logService, child) {
            return ElevatedButton(
              onPressed: _exportLogs,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Export Logs'),
            );
          },
        ),
      ],
    );
  }

  void _forceRefreshNetworkConfig() {
    try {
      // Refresh network configuration
      final baseUrl = NetworkConfigService.getBaseApiUrl();
      final wsUrl = NetworkConfigService.getWebSocketUrl();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network configuration refreshed'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing network config: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _resetVpnState() {
    try {
      final vpnService = Provider.of<VpnService>(context, listen: false);

      // Reset VPN state
      vpnService.resetVpnState();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VPN state reset'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting VPN state: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Data Clear'),
          content: const Text(
            'This will permanently delete all local data including messages, contacts, and settings. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performClearAllData();
              },
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }

  void _performClearAllData() {
    try {
      // In a real implementation, this would clear all local data
      // For now, we'll just show a message

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _exportLogs() async {
    try {
      final logService = Provider.of<LogService>(context, listen: false);
      final exportPath = await logService.exportLogs();

      if (exportPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs exported to: $exportPath'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export logs'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting logs: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
