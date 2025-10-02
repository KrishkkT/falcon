// This is a simple test to verify network configuration
import 'package:flutter/foundation.dart';
import 'package:falcon/services/network_config_service.dart';

void main() {
  // Test network configuration
  debugPrint('Testing network configuration...');

  // Check current settings
  debugPrint('Current server IP: ${NetworkConfigService.getCurrentServerIp()}');
  debugPrint('Base API URL: ${NetworkConfigService.getBaseApiUrl()}');
  debugPrint('WebSocket URL: ${NetworkConfigService.getWebSocketUrl()}');
  debugPrint('Is production mode: ${NetworkConfigService.isProduction()}');

  // Test local development configuration
  NetworkConfigService.updateForLocalNetwork('172.20.10.2', 3001);
  NetworkConfigService.setProductionMode(false);

  debugPrint('\nAfter local config update:');
  debugPrint('Base API URL: ${NetworkConfigService.getBaseApiUrl()}');
  debugPrint('WebSocket URL: ${NetworkConfigService.getWebSocketUrl()}');
  debugPrint('Is production mode: ${NetworkConfigService.isProduction()}');

  // Verify URLs are correct for local development
  assert(NetworkConfigService.getBaseApiUrl() == 'http://172.20.10.2:3001/api');
  assert(NetworkConfigService.getWebSocketUrl() == 'ws://172.20.10.2:3001');
  assert(NetworkConfigService.isProduction() == false);

  debugPrint('\n✅ All network configuration tests passed!');
}
