import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:io' show Platform;

class EnhancedAuditService extends ChangeNotifier {
  static final EnhancedAuditService _instance =
      EnhancedAuditService._internal();
  factory EnhancedAuditService() => _instance;
  EnhancedAuditService._internal();

  final List<AuditLogEntry> _auditLogs = [];
  final List<SecurityEvent> _securityEvents = [];

  List<AuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);
  List<SecurityEvent> get securityEvents => List.unmodifiable(_securityEvents);

  /// Log a general audit event
  Future<void> logAuditEvent({
    required String action,
    required String resourceType,
    String? resourceId,
    String? userId,
    Map<String, dynamic>? details,
    bool success = true,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final timestamp = DateTime.now();

      final logEntry = AuditLogEntry(
        id: _generateLogId(timestamp, action, userId),
        userId: userId,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        details: details ?? {},
        timestamp: timestamp,
        deviceInfo: deviceInfo,
        success: success,
        severity: _getSeverityForAction(action),
      );

      _auditLogs.add(logEntry);

      // Keep only last 1000 logs to prevent memory issues
      if (_auditLogs.length > 1000) {
        _auditLogs.removeRange(0, _auditLogs.length - 1000);
      }

      debugPrint('Audit Log: $action - Success: $success');
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging audit event: $e');
    }
  }

  /// Log a security event
  Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    Map<String, dynamic>? details,
    SecurityLevel level = SecurityLevel.medium,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final timestamp = DateTime.now();

      final securityEvent = SecurityEvent(
        id: _generateLogId(timestamp, eventType, null),
        eventType: eventType,
        description: description,
        details: details ?? {},
        timestamp: timestamp,
        deviceInfo: deviceInfo,
        level: level,
      );

      _securityEvents.add(securityEvent);

      // Keep only last 500 security events
      if (_securityEvents.length > 500) {
        _securityEvents.removeRange(0, _securityEvents.length - 500);
      }

      debugPrint('Security Event: $eventType - Level: $level');
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  /// Log a VPN event
  Future<void> logVpnEvent({
    required String vpnAction,
    required String status,
    Map<String, dynamic>? details,
    bool success = true,
  }) async {
    await logSecurityEvent(
      eventType: 'VPN_$vpnAction',
      description: 'VPN $vpnAction - Status: $status',
      details: {
        'vpn_action': vpnAction,
        'status': status,
        'success': success,
        ...(details ?? {}),
      },
      level: success ? SecurityLevel.info : SecurityLevel.high,
    );

    await logAuditEvent(
      action: 'VPN_$vpnAction',
      resourceType: 'vpn',
      details: {
        'vpn_action': vpnAction,
        'status': status,
        'success': success,
        ...(details ?? {}),
      },
      success: success,
    );
  }

  /// Log a biometric authentication event
  Future<void> logBiometricEvent({
    required String action,
    required bool success,
    String? userId,
    Map<String, dynamic>? details,
  }) async {
    final level = success ? SecurityLevel.info : SecurityLevel.high;

    await logSecurityEvent(
      eventType: 'BIOMETRIC_AUTH',
      description: 'Biometric authentication $action - Success: $success',
      details: {
        'biometric_action': action,
        'success': success,
        'user_id': userId,
        ...(details ?? {}),
      },
      level: level,
    );

    await logAuditEvent(
      action: 'BIOMETRIC_$action',
      resourceType: 'authentication',
      userId: userId,
      details: {
        'biometric_action': action,
        'success': success,
        ...(details ?? {}),
      },
      success: success,
    );
  }

  /// Log a message event
  Future<void> logMessageEvent({
    required String messageType,
    required String action,
    String? messageId,
    String? senderId,
    String? recipientId,
    bool success = true,
    Map<String, dynamic>? details,
  }) async {
    await logAuditEvent(
      action: 'MESSAGE_$action',
      resourceType: 'message',
      resourceId: messageId,
      userId: senderId,
      details: {
        'message_type': messageType,
        'action': action,
        'sender_id': senderId,
        'recipient_id': recipientId,
        'success': success,
        ...(details ?? {}),
      },
      success: success,
    );
  }

  /// Log a session event
  Future<void> logSessionEvent({
    required String action,
    String? userId,
    String? sessionId,
    bool success = true,
    Map<String, dynamic>? details,
  }) async {
    final level = success ? SecurityLevel.info : SecurityLevel.high;

    await logSecurityEvent(
      eventType: 'SESSION_$action',
      description: 'Session $action - Success: $success',
      details: {
        'session_action': action,
        'user_id': userId,
        'session_id': sessionId,
        'success': success,
        ...(details ?? {}),
      },
      level: level,
    );

    await logAuditEvent(
      action: 'SESSION_$action',
      resourceType: 'session',
      resourceId: sessionId,
      userId: userId,
      details: {
        'session_action': action,
        'session_id': sessionId,
        'success': success,
        ...(details ?? {}),
      },
      success: success,
    );
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceData = <String, dynamic>{};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData['platform'] = 'Android';
        deviceData['model'] = androidInfo.model;
        deviceData['version'] = androidInfo.version.release;
        deviceData['manufacturer'] = androidInfo.manufacturer;
        deviceData['id'] = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData['platform'] = 'iOS';
        deviceData['model'] = iosInfo.model;
        deviceData['version'] = iosInfo.systemVersion;
        deviceData['name'] = iosInfo.name;
        deviceData['identifier'] = iosInfo.identifierForVendor;
      }

      return deviceData;
    } catch (e) {
      return {'platform': 'unknown', 'error': e.toString()};
    }
  }

  /// Generate a unique log ID
  String _generateLogId(DateTime timestamp, String action, String? userId) {
    final data = '${timestamp.millisecondsSinceEpoch}_${action}_$userId';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Get severity level based on action
  SecurityLevel _getSeverityForAction(String action) {
    final highSeverityActions = [
      'LOGIN_FAILED',
      'AUTH_FAILED',
      'SESSION_EXPIRED',
      'ACCOUNT_LOCKED',
      'VPN_DISCONNECTED',
      'BIOMETRIC_FAILED',
    ];

    final lowSeverityActions = [
      'VIEW_PROFILE',
      'SEARCH_USERS',
      'VIEW_SETTINGS',
    ];

    if (highSeverityActions.contains(action)) {
      return SecurityLevel.high;
    } else if (lowSeverityActions.contains(action)) {
      return SecurityLevel.low;
    } else {
      return SecurityLevel.medium;
    }
  }

  /// Clear audit logs
  void clearAuditLogs() {
    _auditLogs.clear();
    notifyListeners();
  }

  /// Clear security events
  void clearSecurityEvents() {
    _securityEvents.clear();
    notifyListeners();
  }

  /// Export audit logs as JSON
  String exportAuditLogs() {
    final logs = _auditLogs.map((log) => log.toJson()).toList();
    return jsonEncode(logs);
  }

  /// Export security events as JSON
  String exportSecurityEvents() {
    final events = _securityEvents.map((event) => event.toJson()).toList();
    return jsonEncode(events);
  }
}

/// Audit log entry model
class AuditLogEntry {
  final String id;
  final String? userId;
  final String action;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;
  final bool success;
  final SecurityLevel severity;

  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.details,
    required this.timestamp,
    required this.deviceInfo,
    required this.success,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'device_info': deviceInfo,
      'success': success,
      'severity': severity.toString(),
    };
  }
}

/// Security event model
class SecurityEvent {
  final String id;
  final String eventType;
  final String description;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;
  final SecurityLevel level;

  SecurityEvent({
    required this.id,
    required this.eventType,
    required this.description,
    required this.details,
    required this.timestamp,
    required this.deviceInfo,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'description': description,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'device_info': deviceInfo,
      'level': level.toString(),
    };
  }
}

/// Security level enumeration
enum SecurityLevel {
  low,
  info,
  medium,
  high,
  critical,
}
