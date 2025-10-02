import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      return isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      // First check if biometrics are available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Biometric authentication not available on this device');
        // Try credential authentication as fallback
        return await authenticateWithCredentials();
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      // If biometric authentication fails, try credential authentication as fallback
      if (!didAuthenticate) {
        debugPrint(
            'Biometric authentication failed, trying credential authentication');
        return await authenticateWithCredentials();
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      switch (e.code) {
        case auth_error.notAvailable:
          debugPrint(
              'Biometric authentication not available, trying credential authentication');
          return await authenticateWithCredentials();
        case auth_error.notEnrolled:
          debugPrint(
              'No biometrics enrolled, trying credential authentication');
          return await authenticateWithCredentials();
        case auth_error.lockedOut:
          debugPrint(
              'Biometric authentication locked out, trying credential authentication');
          return await authenticateWithCredentials();
        case auth_error.permanentlyLockedOut:
          debugPrint(
              'Biometric authentication permanently locked out, trying credential authentication');
          return await authenticateWithCredentials();
        default:
          debugPrint(
              'Unknown biometric authentication error: ${e.code}, trying credential authentication');
          return await authenticateWithCredentials();
      }
    } catch (e) {
      debugPrint(
          'Unexpected error during biometric authentication: $e, trying credential authentication');
      return await authenticateWithCredentials();
    }
  }

  /// Authenticate with device credentials (PIN, pattern, password)
  static Future<bool> authenticateWithCredentials() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            'Enter your device PIN, pattern, or password to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Credential authentication error: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during credential authentication: $e');
      return false;
    }
  }
}
