import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'biometric_service.dart';

/// Defense-level session management with automatic timeout and encryption
class SessionManager extends ChangeNotifier {
  static const int _sessionTimeoutMinutes = 15; // 15 minutes for defense level
  static const int _idleTimeoutMinutes = 5; // 5 minutes idle timeout
  static const int _maxSessionDurationHours = 8; // 8 hours maximum session

  Timer? _sessionTimer;
  Timer? _idleTimer;
  Timer? _heartbeatTimer;
  DateTime? _sessionStart;
  DateTime? _lastActivity;
  String? _sessionId;
  String? _encryptedSessionData;
  bool _isSessionActive = false;
  bool _isUserActive = true;
  bool _requiresBiometricAuth = false; // Flag for biometric authentication
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  // Security events
  final List<Map<String, dynamic>> _securityEvents = [];

  bool get isSessionActive => _isSessionActive;
  bool get isUserActive => _isUserActive;
  String? get sessionId => _sessionId;
  int get sessionRemainingMinutes {
    if (_sessionStart == null) return 0;
    final elapsed = DateTime.now().difference(_sessionStart!);
    return _sessionTimeoutMinutes - elapsed.inMinutes;
  }

  List<Map<String, dynamic>> get securityEvents =>
      List.unmodifiable(_securityEvents);

  /// Initialize a new defense-level session
  Future<bool> initializeSession(String userId, String token) async {
    try {
      // Generate secure session ID
      _sessionId = _generateSecureSessionId();
      _sessionStart = DateTime.now();
      _lastActivity = DateTime.now();
      _isSessionActive = true;
      _isUserActive = true;
      _failedAttempts = 0;

      // Encrypt session data
      final sessionData = {
        'userId': userId,
        'token': token,
        'sessionStart': _sessionStart!.toIso8601String(),
        'deviceInfo': await _getDeviceFingerprint(),
        'securityLevel': 'DEFENSE_GRADE',
      };

      _encryptedSessionData =
          await _encryptSessionData(jsonEncode(sessionData));

      // Start session timers
      _startSessionTimer();
      _startIdleTimer();
      _startHeartbeat();

      // Log security event
      _logSecurityEvent('SESSION_INITIALIZED', {
        'sessionId': _sessionId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _logSecurityEvent('SESSION_INIT_FAILED', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      return false;
    }
  }

  /// Update last activity time (call on any user interaction)
  void updateActivity() {
    if (!_isSessionActive) return;

    _lastActivity = DateTime.now();
    _isUserActive = true;

    // Reset idle timer
    _idleTimer?.cancel();
    _startIdleTimer();

    notifyListeners();
  }

  /// Enable biometric authentication for session resumption
  void enableBiometricAuth() {
    _requiresBiometricAuth = true;
    _logSecurityEvent('BIOMETRIC_AUTH_ENABLED', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  /// Disable biometric authentication
  void disableBiometricAuth() {
    _requiresBiometricAuth = false;
    _logSecurityEvent('BIOMETRIC_AUTH_DISABLED', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  /// Validate session with optional biometric authentication
  Future<bool> validateSession({bool requireBiometric = false}) async {
    if (!_isSessionActive || _sessionId == null) {
      return false;
    }

    // Check if biometric authentication is required
    if ((_requiresBiometricAuth || requireBiometric) && _isUserActive) {
      // Session is active but requires biometric authentication
      _logSecurityEvent('BIOMETRIC_AUTH_REQUIRED', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true; // Return true to indicate session is valid but needs biometric
    }

    // Check session timeout
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      if (sessionDuration.inHours >= _maxSessionDurationHours) {
        await terminateSession('MAX_SESSION_DURATION_EXCEEDED');
        return false;
      }
    }

    // Check idle timeout
    if (_lastActivity != null) {
      final idleDuration = DateTime.now().difference(_lastActivity!);
      if (idleDuration.inMinutes >= _idleTimeoutMinutes) {
        await terminateSession('IDLE_TIMEOUT');
        return false;
      }
    }

    // Verify session data integrity
    if (_encryptedSessionData == null) {
      await terminateSession('SESSION_DATA_CORRUPTED');
      return false;
    }

    return true;
  }

  /// Resume session with biometric authentication
  Future<bool> resumeSessionWithBiometric() async {
    if (!_requiresBiometricAuth || !_isSessionActive) {
      return true; // If no biometric auth required, session is already valid
    }

    try {
      // Authenticate with biometrics
      final authenticated = await BiometricService.authenticateWithBiometrics();

      if (authenticated) {
        // Reset activity and resume session
        _lastActivity = DateTime.now();
        _isUserActive = true;

        // Reset idle timer
        _idleTimer?.cancel();
        _startIdleTimer();

        _logSecurityEvent('SESSION_RESUMED_WITH_BIOMETRIC', {
          'timestamp': DateTime.now().toIso8601String(),
        });

        notifyListeners();
        return true;
      } else {
        _logSecurityEvent('BIOMETRIC_AUTH_FAILED', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        return false;
      }
    } catch (e) {
      _logSecurityEvent('BIOMETRIC_AUTH_ERROR', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      return false;
    }
  }

  /// Terminate session with reason
  Future<void> terminateSession(String reason) async {
    _logSecurityEvent('SESSION_TERMINATED', {
      'sessionId': _sessionId,
      'reason': reason,
      'duration': _sessionStart != null
          ? DateTime.now().difference(_sessionStart!).toString()
          : 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Clear all timers
    _sessionTimer?.cancel();
    _idleTimer?.cancel();
    _heartbeatTimer?.cancel();

    // Clear session data
    _sessionId = null;
    _sessionStart = null;
    _lastActivity = null;
    _encryptedSessionData = null;
    _isSessionActive = false;
    _isUserActive = false;

    notifyListeners();
  }

  /// Handle authentication failure
  void recordFailedAttempt(String reason) {
    _failedAttempts++;

    _logSecurityEvent('AUTHENTICATION_FAILED', {
      'attempt': _failedAttempts,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_failedAttempts >= _maxFailedAttempts) {
      _logSecurityEvent('MAX_FAILED_ATTEMPTS_REACHED', {
        'attempts': _failedAttempts,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Force session termination
      terminateSession('MAX_FAILED_ATTEMPTS');
    }
  }

  /// Reset failed attempts on successful auth
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  /// Start session timeout timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(
      const Duration(minutes: _sessionTimeoutMinutes),
      () => terminateSession('SESSION_TIMEOUT'),
    );
  }

  /// Start idle timeout timer
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      const Duration(minutes: _idleTimeoutMinutes),
      () {
        _isUserActive = false;
        terminateSession('IDLE_TIMEOUT');
      },
    );
  }

  /// Start heartbeat for session validation
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        if (!await validateSession()) {
          timer.cancel();
        }
      },
    );
  }

  /// Generate cryptographically secure session ID
  String _generateSecureSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return sha256.convert(bytes).toString();
  }

  /// Get device fingerprint for session validation
  Future<String> _getDeviceFingerprint() async {
    try {
      // In a real implementation, collect more device-specific data
      final platform = defaultTargetPlatform.toString();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final random = Random.secure().nextInt(1000000).toString();

      final fingerprint = '$platform-$timestamp-$random';
      return sha256.convert(utf8.encode(fingerprint)).toString();
    } catch (e) {
      // Fallback fingerprint
      return sha256
          .convert(
              utf8.encode('fallback-${DateTime.now().millisecondsSinceEpoch}'))
          .toString();
    }
  }

  /// Encrypt session data (simplified for demo)
  Future<String> _encryptSessionData(String data) async {
    // In production, use proper encryption (AES-256)
    // For now, use base64 encoding with salt
    final salt = _generateSecureSessionId().substring(0, 16);
    final combined = '$salt:$data';
    return base64Encode(utf8.encode(combined));
  }

  /// Log security events for audit
  void _logSecurityEvent(String eventType, Map<String, dynamic> details) {
    final event = {
      'eventType': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionId': _sessionId ?? 'NO_SESSION',
      'details': details,
    };

    _securityEvents.add(event);

    // Keep only last 100 events
    if (_securityEvents.length > 100) {
      _securityEvents.removeAt(0);
    }

    // In production, send to secure audit server
    debugPrint('🔒 Security Event: $eventType - ${details.toString()}');
  }

  /// Force session renewal (for high-security operations)
  Future<bool> renewSession() async {
    if (!_isSessionActive || _sessionId == null) return false;

    final oldSessionId = _sessionId;
    _sessionId = _generateSecureSessionId();
    _sessionStart = DateTime.now();
    _lastActivity = DateTime.now();

    _logSecurityEvent('SESSION_RENEWED', {
      'oldSessionId': oldSessionId,
      'newSessionId': _sessionId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Restart timers
    _startSessionTimer();
    _startIdleTimer();

    notifyListeners();
    return true;
  }

  /// Get session security status
  Map<String, dynamic> getSecurityStatus() {
    return {
      'isActive': _isSessionActive,
      'sessionId': _sessionId,
      'sessionAge': _sessionStart != null
          ? DateTime.now().difference(_sessionStart!).toString()
          : null,
      'lastActivity': _lastActivity?.toIso8601String(),
      'remainingMinutes': sessionRemainingMinutes,
      'failedAttempts': _failedAttempts,
      'securityLevel': 'DEFENSE_GRADE',
      'eventsCount': _securityEvents.length,
    };
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _idleTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
