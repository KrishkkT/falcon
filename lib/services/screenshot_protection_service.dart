import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenshotProtectionService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('falcon/screenshot_protection');

  bool _isScreenshotProtectionEnabled = true; // Enable by default
  bool _isScreenRecordingProtectionEnabled = true; // Enable by default

  bool get isScreenshotProtectionEnabled => _isScreenshotProtectionEnabled;
  bool get isScreenRecordingProtectionEnabled =>
      _isScreenRecordingProtectionEnabled;

  /// Enable screenshot protection
  Future<void> enableScreenshotProtection() async {
    try {
      await _channel.invokeMethod('enableScreenshotProtection');
      _isScreenshotProtectionEnabled = true;
      debugPrint('Screenshot protection enabled');
      notifyListeners();
    } catch (e) {
      debugPrint('Error enabling screenshot protection: $e');
      // Even if native method fails, we still enable overlay protection
      _isScreenshotProtectionEnabled = true;
      notifyListeners();
    }
  }

  /// Disable screenshot protection
  Future<void> disableScreenshotProtection() async {
    try {
      await _channel.invokeMethod('disableScreenshotProtection');
      _isScreenshotProtectionEnabled = false;
      debugPrint('Screenshot protection disabled');
      notifyListeners();
    } catch (e) {
      debugPrint('Error disabling screenshot protection: $e');
      // Even if native method fails, we still disable overlay protection
      _isScreenshotProtectionEnabled = false;
      notifyListeners();
    }
  }

  /// Enable screen recording protection
  Future<void> enableScreenRecordingProtection() async {
    try {
      await _channel.invokeMethod('enableScreenRecordingProtection');
      _isScreenRecordingProtectionEnabled = true;
      debugPrint('Screen recording protection enabled');
      notifyListeners();
    } catch (e) {
      debugPrint('Error enabling screen recording protection: $e');
      // Even if native method fails, we still enable protection
      _isScreenRecordingProtectionEnabled = true;
      notifyListeners();
    }
  }

  /// Disable screen recording protection
  Future<void> disableScreenRecordingProtection() async {
    try {
      await _channel.invokeMethod('disableScreenRecordingProtection');
      _isScreenRecordingProtectionEnabled = false;
      debugPrint('Screen recording protection disabled');
      notifyListeners();
    } catch (e) {
      debugPrint('Error disabling screen recording protection: $e');
      // Even if native method fails, we still disable protection
      _isScreenRecordingProtectionEnabled = false;
      notifyListeners();
    }
  }

  /// Toggle screenshot protection
  Future<void> toggleScreenshotProtection() async {
    if (_isScreenshotProtectionEnabled) {
      await disableScreenshotProtection();
    } else {
      await enableScreenshotProtection();
    }
  }

  /// Toggle screen recording protection
  Future<void> toggleScreenRecordingProtection() async {
    if (_isScreenRecordingProtectionEnabled) {
      await disableScreenRecordingProtection();
    } else {
      await enableScreenRecordingProtection();
    }
  }

  /// Initialize protection (called at app startup)
  Future<void> initialize() async {
    // Enable protection by default
    await enableScreenshotProtection();
    await enableScreenRecordingProtection();
  }
}
