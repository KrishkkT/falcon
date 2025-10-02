import 'dart:io';
import 'package:flutter/foundation.dart';
import 'network_config_service.dart';

class ConfigService {
  // Default configuration values
  static bool _forceVpnLocal = true;
  static String _serverMode = 'local'; // 'local' or 'aws'
  static bool _useVpn = false;

  // Getters
  static bool get forceVpnLocal => _forceVpnLocal;
  static String get serverMode => _serverMode;
  static bool get useVpn => _useVpn;

  /// Initialize configuration from environment or backend
  static Future<void> initialize() async {
    try {
      // For development, read from environment variables if available
      if (kDebugMode) {
        // In debug mode, we can check for environment-like configuration
        _forceVpnLocal = bool.fromEnvironment('FORCE_VPN_LOCAL', defaultValue: true);
        _serverMode = const String.fromEnvironment('SERVER_MODE', defaultValue: 'local');
        _useVpn = bool.fromEnvironment('USE_VPN', defaultValue: false);
      } else {
        // In production, we might fetch configuration from backend
        // For now, we'll use default values
        _forceVpnLocal = true;
        _serverMode = 'local';
        _useVpn = false;
      }
      
      // Apply configuration to network service
      _applyConfiguration();
      
      debugPrint('Configuration initialized:');
      debugPrint('  Force VPN Local: $_forceVpnLocal');
      debugPrint('  Server Mode: $_serverMode');
      debugPrint('  Use VPN: $_useVpn');
    } catch (e) {
      debugPrint('Error initializing configuration: $e');
      // Use default values
      _forceVpnLocal = true;
      _serverMode = 'local';
      _useVpn = false;
      _applyConfiguration();
    }
  }

  /// Apply configuration to network service
  static void _applyConfiguration() {
    NetworkConfigService.setForceVpnLocal(_forceVpnLocal);
    
    if (_serverMode == 'aws') {
      NetworkConfigService.setProductionMode(true);
      // For AWS, we would set the appropriate server IP
      NetworkConfigService.updateForRealDevice('172.20.10.2', 80);
    } else {
      NetworkConfigService.setProductionMode(false);
      NetworkConfigService.updateForLocalNetwork('172.20.10.2', 3001);
    }
    
    NetworkConfigService.setVpnStatus(_useVpn);
  }

  /// Set force VPN local mode
  static void setForceVpnLocal(bool value) {
    _forceVpnLocal = value;
    NetworkConfigService.setForceVpnLocal(value);
    debugPrint('Force VPN local mode set to: $value');
  }

  /// Set server mode
  static void setServerMode(String mode) {
    _serverMode = mode;
    if (mode == 'aws') {
      NetworkConfigService.setProductionMode(true);
      NetworkConfigService.updateForRealDevice('172.20.10.2', 80);
    } else {
      NetworkConfigService.setProductionMode(false);
      NetworkConfigService.updateForLocalNetwork('172.20.10.2', 3001);
    }
    debugPrint('Server mode set to: $mode');
  }

  /// Set VPN usage
  static void setUseVpn(bool value) {
    _useVpn = value;
    NetworkConfigService.setVpnStatus(value);
    debugPrint('VPN usage set to: $value');
  }

  /// Get all 4 mode combinations
  static void setMode(String serverMode, bool useVpn) {
    setServerMode(serverMode);
    setUseVpn(useVpn);
    
    debugPrint('Mode set to: $serverMode with VPN: $useVpn');
  }
}