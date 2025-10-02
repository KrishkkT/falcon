import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'network_config_service.dart';

class VpnService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('falcon/vpn_manager');

  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  String? _vpnError;
  DateTime? _lastConnectionAttempt;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;

  /// Reset VPN state to initial values
  void resetVpnState() {
    _isConnected = false;
    _isConnecting = false;
    _connectionStatus = 'disconnected';
    _vpnError = null;
    _lastConnectionAttempt = null;
    notifyListeners();
    debugPrint('VPN state reset to initial values');
  }

  /// Check if VPN permission is granted
  Future<bool> isVpnPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod('isVpnPermissionGranted');
      return result is bool ? result : false;
    } on PlatformException catch (e) {
      debugPrint('Platform error checking VPN permission: $e');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('VPN plugin not available: $e');
      return false;
    } catch (e) {
      debugPrint('Error checking VPN permission: $e');
      return false;
    }
  }

  /// Request VPN permission
  Future<bool> requestVpnPermission() async {
    try {
      final result = await _channel.invokeMethod('requestVpnPermission');
      return result is bool ? result : false;
    } on PlatformException catch (e) {
      debugPrint('Platform error requesting VPN permission: $e');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('VPN plugin not available: $e');
      return false;
    } catch (e) {
      debugPrint('Error requesting VPN permission: $e');
      return false;
    }
  }

  /// Start VPN connection with retry mechanism
  Future<void> startVpn({int retryCount = 0}) async {
    try {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
      notifyListeners();

      final result = await _channel.invokeMethod('startVpn');

      if (result != null) {
        _isConnected = true;
        _isConnecting = false;
        _connectionStatus = 'Connected';
        debugPrint('VPN started successfully: $result');
        // Notify network config service about VPN status change
        NetworkConfigService.setVpnStatus(true);
      } else {
        throw Exception('Failed to start VPN');
      }
    } on PlatformException catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Connection failed';
      debugPrint('Platform error starting VPN: $e');
      // Notify network config service about VPN status change
      NetworkConfigService.setVpnStatus(false);

      // Retry mechanism for platform errors
      if (retryCount < 2) {
        debugPrint('Retrying VPN start (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await startVpn(retryCount: retryCount + 1);
      }

      rethrow;
    } on MissingPluginException catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Plugin not available';
      debugPrint('VPN plugin not available: $e');
      // Notify network config service about VPN status change
      NetworkConfigService.setVpnStatus(false);
      rethrow;
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Connection failed';
      debugPrint('Error starting VPN: $e');
      // Notify network config service about VPN status change
      NetworkConfigService.setVpnStatus(false);

      // Retry mechanism for other errors
      if (retryCount < 1) {
        debugPrint(
            'Retrying VPN start due to unknown error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await startVpn(retryCount: retryCount + 1);
      }

      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Stop VPN connection with retry mechanism
  Future<void> stopVpn({int retryCount = 0}) async {
    try {
      await _channel.invokeMethod('stopVpn');
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Disconnected';
      // Notify network config service about VPN status change
      NetworkConfigService.setVpnStatus(false);
      notifyListeners();
      debugPrint('VPN stopped successfully');
    } on PlatformException catch (e) {
      debugPrint('Platform error stopping VPN: $e');

      // Retry mechanism for platform errors
      if (retryCount < 2) {
        debugPrint('Retrying VPN stop (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await stopVpn(retryCount: retryCount + 1);
      }

      rethrow;
    } on MissingPluginException catch (e) {
      debugPrint('VPN plugin not available: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error stopping VPN: $e');

      // Retry mechanism for other errors
      if (retryCount < 1) {
        debugPrint(
            'Retrying VPN stop due to unknown error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await stopVpn(retryCount: retryCount + 1);
      }

      rethrow;
    }
  }

  /// Get current VPN status with error handling
  Future<String> getVpnStatus() async {
    try {
      final status = await _channel.invokeMethod('getVpnStatus');
      _connectionStatus = status is String ? status : 'Unknown';
      notifyListeners();
      return _connectionStatus;
    } on PlatformException catch (e) {
      debugPrint('Platform error getting VPN status: $e');
      return 'Error';
    } on MissingPluginException catch (e) {
      debugPrint('VPN plugin not available: $e');
      return 'Plugin not available';
    } catch (e) {
      debugPrint('Error getting VPN status: $e');
      return 'Error';
    }
  }

  /// Toggle VPN connection with error handling
  Future<void> toggleVpn() async {
    try {
      if (_isConnected) {
        await stopVpn();
      } else {
        await startVpn();
      }
    } catch (e) {
      debugPrint('Error toggling VPN: $e');
      // Re-throw to let the caller handle the error
      rethrow;
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
