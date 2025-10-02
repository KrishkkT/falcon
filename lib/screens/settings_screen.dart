import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/config_service.dart';
import '../services/network_config_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _forceVpnLocal;
  late String _serverMode;
  late bool _useVpn;

  @override
  void initState() {
    super.initState();
    _forceVpnLocal = ConfigService.forceVpnLocal;
    _serverMode = ConfigService.serverMode;
    _useVpn = ConfigService.useVpn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Theme Settings'),
            _buildThemeOptions(),
            const SizedBox(height: 16),
            _buildSectionHeader('VPN Configuration'),
            _buildSwitchListTile(
              title: 'Force VPN Local Mode',
              subtitle: 'Enable split tunneling for local development with VPN',
              value: _forceVpnLocal,
              onChanged: (value) {
                setState(() {
                  _forceVpnLocal = value;
                  ConfigService.setForceVpnLocal(value);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Server Configuration'),
            _buildSegmentedControl(
              title: 'Server Mode',
              options: const ['Local'],
              selected: _serverMode,
              onSelected: (String value) {
                setState(() {
                  _serverMode = value.toLowerCase();
                  ConfigService.setServerMode(value.toLowerCase());
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Connection Modes'),
            _buildModeCard(
              title: 'Local Development with VPN',
              description:
                  'Use local server (172.20.10.2:3001) with VPN enabled',
              isSelected: _serverMode == 'local' && _useVpn,
              onTap: () {
                setState(() {
                  _serverMode = 'local';
                  _useVpn = true;
                  ConfigService.setMode('local', true);
                });
              },
            ),
            _buildModeCard(
              title: 'Local Development without VPN',
              description:
                  'Use local server (172.20.10.2:3001) with VPN disabled',
              isSelected: _serverMode == 'local' && !_useVpn,
              onTap: () {
                setState(() {
                  _serverMode = 'local';
                  _useVpn = false;
                  ConfigService.setMode('local', false);
                });
              },
            ),
            const SizedBox(height: 32),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkColor,
        ),
      ),
    );
  }

  Widget _buildThemeOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.mediumRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeService.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    if (newSelection.isNotEmpty) {
                      themeService.setThemeMode(newSelection.first);
                    }
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryColor;
                        }
                        return null;
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.mediumRadius,
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSegmentedControl({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.mediumRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return SegmentedButton<String>(
                  segments: options
                      .map(
                        (option) => ButtonSegment(
                          value: option,
                          label: Text(option),
                        ),
                      )
                      .toList(),
                  selected: {selected.capitalize()},
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isNotEmpty) {
                      onSelected(newSelection.first.toLowerCase());
                    }
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryColor;
                        }
                        return null;
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.mediumRadius,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(description),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.mediumRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Force VPN Local: ${ConfigService.forceVpnLocal}'),
            Text('Server Mode: ${ConfigService.serverMode.capitalize()}'),
            Text('Use VPN: ${ConfigService.useVpn}'),
            const SizedBox(height: 8),
            const Text(
              'Note: Changes take effect immediately. Restart the app if issues occur.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}
