import 'dart:io';

class NetworkUtils {
  /// Test if we can connect to the server
  static Future<bool> testServerConnectivity(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final client = HttpClient();

      // Set a short timeout for quick testing
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(uri);
      final response = await request.close();

      client.close();

      return response.statusCode == 200;
    } catch (e) {
      // Simple print instead of debugPrint to avoid import issues
      print('Server connectivity test failed: $e');
      return false;
    }
  }

  /// Get the best URL to use based on network conditions
  static Future<String> getOptimalBaseUrl(
    String baseUrl,
    bool isVpnActive,
  ) async {
    // If VPN is not active, use the default URL
    if (!isVpnActive) {
      return baseUrl;
    }

    // If VPN is active, test if we can reach the server
    final canConnect = await testServerConnectivity(baseUrl);

    if (canConnect) {
      print('VPN active but can connect to server directly');
      return baseUrl;
    } else {
      print(
        'VPN active and cannot connect directly, suggesting alternative approach',
      );
      return baseUrl; // Still return the same URL but with warning
    }
  }

  /// Check if we're likely dealing with a local development server
  static bool isLocalDevelopmentServer(String baseUrl) {
    try {
      final uri = Uri.parse(baseUrl);
      final host = uri.host;

      // Check for common local development patterns
      return host == 'localhost' ||
          host == '127.0.0.1' ||
          host.startsWith('192.168.') ||
          host.startsWith('10.') ||
          host.startsWith('172.');
    } catch (e) {
      return false;
    }
  }

  /// Check if we're in a local development environment
  static Future<bool> isLocalDevelopmentEnvironment() async {
    // Check common local development IP patterns
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: true,
        includeLinkLocal: true,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          // Check if any interface has a local development IP
          if (address.address.startsWith('192.168.') ||
              address.address.startsWith('10.') ||
              address.address.startsWith('172.')) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      // If we can't list network interfaces, assume we're not in local dev
      return false;
    }
  }
  
  /// Test connection to a specific host and port
  static Future<bool> testConnection(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      print('Connection test to $host:$port failed: $e');
      return false;
    }
  }
}