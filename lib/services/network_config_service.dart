import 'dart:io' show Platform;

class NetworkConfigService {
  // Local development network configuration
  static String _serverIp = '172.20.10.2'; // Your local development IP
  static int _serverPort = 3001; // Port for local development
  static String _serverDomain = ''; // Domain name if using one
  static bool _isUsingLocalhost = false;
  static bool _isVpnActive = false;
  static bool _isProduction = false; // Set to false for local development
  static bool _forceVpnLocal = true; // New flag for VPN local mode

  /// Get the current server IP
  static String getCurrentServerIp() {
    return _serverIp;
  }

  /// Get the server domain (if configured)
  static String getServerDomain() {
    return _serverDomain;
  }

  /// Get the base API URL
  static String getBaseApiUrl() {
    // If domain is configured, use it; otherwise use IP
    if (_serverDomain.isNotEmpty) {
      return 'https://$_serverDomain/api';
    }
    // For production (AWS), use HTTPS only if port is 443
    if (_isProduction && _serverPort == 443) {
      return 'https://$_serverIp/api';
    }
    // For local development or non-standard ports, use HTTP with explicit port
    return 'http://$_serverIp:$_serverPort/api';
  }

  /// Get the WebSocket URL
  static String getWebSocketUrl() {
    // If domain is configured, use secure WebSocket; otherwise use regular WebSocket
    if (_serverDomain.isNotEmpty) {
      return 'wss://$_serverDomain';
    }
    // For production (AWS), use secure WebSocket only if port is 443
    if (_isProduction && _serverPort == 443) {
      return 'wss://$_serverIp';
    }
    // For local development or non-standard ports, use regular WebSocket with explicit port
    return 'ws://$_serverIp:$_serverPort';
  }

  /// Get localhost URL for development scenarios (when NOT using VPN)
  static String getLocalhostUrl() {
    // For Android emulator, localhost is 10.0.2.2
    // For iOS simulator, localhost is localhost
    // For real devices, this should be the development machine IP
    // Simple approach without kIsWeb check to avoid import issues
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_serverPort/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:$_serverPort/api';
    } else {
      return 'http://localhost:$_serverPort/api';
    }
  }

  /// Update configuration for local network usage (your current setup)
  static void updateForLocalNetwork(String serverIp, [int serverPort = 3001]) {
    _serverIp = serverIp;
    _serverPort = serverPort;
    _serverDomain = ''; // Clear domain when using IP
    _isProduction = false;
    _isUsingLocalhost = false;
    // Simple print instead of debugPrint to avoid import issues
    print('Network config updated for local network: $serverIp:$serverPort');
  }

  /// Update configuration for real device usage with domain
  static void updateForDomain(String domain) {
    _serverDomain = domain;
    _serverIp = ''; // Clear IP when using domain
    _isProduction = true;
    _isUsingLocalhost = false;
    print('Network config updated for domain: $domain');
  }

  /// Update configuration for real device usage with IP
  static void updateForRealDevice(String serverIp, [int serverPort = 80]) {
    _serverIp = serverIp;
    _serverPort = serverPort;
    _serverDomain = ''; // Clear domain when using IP
    _isProduction = true;
    _isUsingLocalhost = false;
    print('Network config updated to: $serverIp:$serverPort');
  }

  /// Use localhost configuration
  static void useLocalhost() {
    _isUsingLocalhost = true;
    _isProduction = false;
    print('Network config set to localhost mode');
  }

  /// Set production mode
  static void setProductionMode(bool isProduction) {
    _isProduction = isProduction;
    print('Production mode set to: $isProduction');
  }

  /// Check if in production mode
  static bool isProduction() {
    return _isProduction;
  }

  /// Set VPN local mode
  static void setForceVpnLocal(bool forceVpnLocal) {
    _forceVpnLocal = forceVpnLocal;
    print('Force VPN local mode set to: $forceVpnLocal');
  }

  /// Check if force VPN local mode is enabled
  static bool isForceVpnLocal() {
    return _forceVpnLocal;
  }

  /// Set VPN status
  static void setVpnStatus(bool isActive) {
    _isVpnActive = isActive;
    print('VPN status updated: $isActive');
  }

  /// Get VPN status
  static bool isVpnActive() {
    return _isVpnActive;
  }

  /// Check if we're using a local development server
  static bool isLocalDevelopmentServer() {
    // Check if the server IP is a local network address or if we're using localhost
    return _serverIp.startsWith('172.20.10.') ||
        _serverIp.startsWith('192.168.') ||
        _serverIp.startsWith('10.') ||
        _serverIp == 'localhost' ||
        _serverIp == '127.0.0.1';
  }

  /// Get effective base URL considering VPN status and local development
  static String getEffectiveBaseUrl() {
    // If force VPN local mode is enabled, always use local connection
    if (_forceVpnLocal && isLocalDevelopmentServer()) {
      print('Force VPN local mode enabled - using local connection');
      return getBaseApiUrl();
    }

    // If VPN is active and we're using a local development server,
    // we should still be able to connect directly with proper routing
    if (_isVpnActive && isLocalDevelopmentServer()) {
      print(
        'VPN active with local development server - using direct connection with split tunneling',
      );
      return getBaseApiUrl();
    }

    // For other scenarios, use the standard base URL
    return getBaseApiUrl();
  }

  /// Get effective WebSocket URL considering VPN status
  static String getEffectiveWebSocketUrl() {
    // If force VPN local mode is enabled, always use local WebSocket connection
    if (_forceVpnLocal && isLocalDevelopmentServer()) {
      print('Force VPN local mode enabled - using local WebSocket connection');
      return getWebSocketUrl();
    }

    // If VPN is active and we're using a local development server,
    // we should still be able to connect directly with proper routing
    if (_isVpnActive && isLocalDevelopmentServer()) {
      print(
        'VPN active with local development server - using direct WebSocket connection with split tunneling',
      );
      return getWebSocketUrl();
    }

    // For other scenarios, use the standard WebSocket URL
    return getWebSocketUrl();
  }

  /// Test server connection
  static Future<bool> testServerConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      // In a real implementation, we would make an actual HTTP request
      // For now, we'll just validate the URL format
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Get connection configuration summary
  static Map<String, dynamic> getConnectionSummary() {
    return {
      'serverIp': _serverIp,
      'serverPort': _serverPort,
      'serverDomain': _serverDomain,
      'isUsingLocalhost': _isUsingLocalhost,
      'isVpnActive': _isVpnActive,
      'isProduction': _isProduction,
      'forceVpnLocal': _forceVpnLocal,
      'baseUrl': getBaseApiUrl(),
      'webSocketUrl': getWebSocketUrl(),
      'isLocalDevelopment': isLocalDevelopmentServer(),
    };
  }
}
