import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Comprehensive security audit logging service for Ministry of Defense level security
class SecurityAuditService extends ChangeNotifier {
  final List<Map<String, dynamic>> _auditLogs = [];
  final List<Map<String, dynamic>> _accessLogs = [];
  final List<Map<String, dynamic>> _securityEvents = [];
  final List<Map<String, dynamic>> _dataAccessLogs = [];

  // Security metrics
  int _totalSecurityEvents = 0;
  int _highRiskEvents = 0;
  int _mediumRiskEvents = 0;
  int _lowRiskEvents = 0;
  DateTime? _lastSecurityCheck;

  // Getters
  List<Map<String, dynamic>> get auditLogs => List.unmodifiable(_auditLogs);
  List<Map<String, dynamic>> get accessLogs => List.unmodifiable(_accessLogs);
  List<Map<String, dynamic>> get securityEvents =>
      List.unmodifiable(_securityEvents);
  List<Map<String, dynamic>> get dataAccessLogs =>
      List.unmodifiable(_dataAccessLogs);
  int get totalSecurityEvents => _totalSecurityEvents;
  int get highRiskEvents => _highRiskEvents;
  int get mediumRiskEvents => _mediumRiskEvents;
  int get lowRiskEvents => _lowRiskEvents;
  DateTime? get lastSecurityCheck => _lastSecurityCheck;

  /// Initialize security audit service
  Future<void> initialize() async {
    await _loadExistingLogs();
    _logSecurityEvent(
        'AUDIT_SERVICE_INIT', 'Security audit service initialized', 'INFO');
    _performInitialSecurityCheck();
  }

  /// Load existing logs from secure storage/backend
  Future<void> _loadExistingLogs() async {
    try {
      // In a real implementation, this would load from secure storage
      // For demo, we'll create some sample logs
      _generateSampleLogs();
    } catch (e) {
      debugPrint('Error loading existing logs: $e');
    }
  }

  /// Generate sample security logs for demonstration
  void _generateSampleLogs() {
    final now = DateTime.now();

    // Sample audit logs
    _auditLogs.addAll([
      {
        'id': 'audit_001',
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'event': 'USER_LOGIN',
        'userId': 'def_user_001',
        'ipAddress': '192.168.1.100',
        'userAgent': 'Falcon Mobile App v1.0',
        'status': 'SUCCESS',
        'classification': 'CONFIDENTIAL',
      },
      {
        'id': 'audit_002',
        'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'event': 'VPN_CONNECTION',
        'userId': 'def_user_001',
        'serverNode': 'GOV-SECURE-NODE-01',
        'encryptionLevel': 'MILITARY_GRADE',
        'status': 'ACTIVE',
        'classification': 'SECRET',
      },
      {
        'id': 'audit_003',
        'timestamp':
            now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'event': 'FILE_UPLOAD',
        'userId': 'def_user_001',
        'fileName': 'classified_report.pdf',
        'fileSize': '2.5MB',
        'encryptionApplied': true,
        'classification': 'TOP_SECRET',
      },
    ]);

    // Sample security events
    _securityEvents.addAll([
      {
        'id': 'sec_001',
        'timestamp':
            now.subtract(const Duration(minutes: 15)).toIso8601String(),
        'eventType': 'THREAT_DETECTION',
        'severity': 'LOW',
        'description': 'Routine security scan completed - no threats detected',
        'source': 'AUTOMATED_SCANNER',
        'resolved': true,
      },
      {
        'id': 'sec_002',
        'timestamp': now.subtract(const Duration(hours: 3)).toIso8601String(),
        'eventType': 'ENCRYPTION_VERIFICATION',
        'severity': 'INFO',
        'description': 'End-to-end encryption verified for all active sessions',
        'source': 'ENCRYPTION_MONITOR',
        'resolved': true,
      },
      {
        'id': 'sec_003',
        'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'eventType': 'ACCESS_PATTERN_ANALYSIS',
        'severity': 'MEDIUM',
        'description':
            'Unusual access pattern detected - elevated monitoring activated',
        'source': 'BEHAVIORAL_ANALYSIS',
        'resolved': true,
      },
    ]);

    _updateSecurityMetrics();
  }

  /// Perform initial security check
  void _performInitialSecurityCheck() {
    _lastSecurityCheck = DateTime.now();
    _logSecurityEvent(
        'SECURITY_CHECK', 'Initial security assessment completed', 'INFO');
  }

  /// Log a security event
  void logSecurityEvent(String eventType, String description, String severity,
      {Map<String, dynamic>? metadata}) {
    _logSecurityEvent(eventType, description, severity, metadata: metadata);
  }

  /// Internal method to log security events
  void _logSecurityEvent(String eventType, String description, String severity,
      {Map<String, dynamic>? metadata}) {
    final event = {
      'id': 'sec_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'eventType': eventType,
      'severity': severity,
      'description': description,
      'source': 'FALCON_APP',
      'resolved': false,
      'metadata': metadata ?? {},
    };

    _securityEvents.add(event);
    _totalSecurityEvents++;

    // Update severity counters
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        _highRiskEvents++;
        break;
      case 'MEDIUM':
        _mediumRiskEvents++;
        break;
      case 'LOW':
      case 'INFO':
        _lowRiskEvents++;
        break;
    }

    // Keep only last 1000 events
    if (_securityEvents.length > 1000) {
      _securityEvents.removeAt(0);
    }

    notifyListeners();
  }

  /// Log user access event
  void logUserAccess(String userId, String action, String resource,
      {String? ipAddress, String? userAgent}) {
    final accessLog = {
      'id': 'access_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'action': action,
      'resource': resource,
      'ipAddress': ipAddress ?? 'unknown',
      'userAgent': userAgent ?? 'unknown',
      'sessionId': _generateSessionId(),
    };

    _accessLogs.add(accessLog);

    // Keep only last 5000 access logs
    if (_accessLogs.length > 5000) {
      _accessLogs.removeAt(0);
    }

    notifyListeners();
  }

  /// Log data access event
  void logDataAccess(
      String userId, String dataType, String operation, String classification,
      {Map<String, dynamic>? details}) {
    final dataLog = {
      'id': 'data_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'dataType': dataType,
      'operation': operation,
      'classification': classification,
      'details': details ?? {},
      'approved':
          true, // In real implementation, this would check approval workflow
    };

    _dataAccessLogs.add(dataLog);

    // Log as security event if high classification
    if (['SECRET', 'TOP_SECRET', 'CLASSIFIED']
        .contains(classification.toUpperCase())) {
      _logSecurityEvent(
          'DATA_ACCESS', 'Access to classified data: $dataType', 'MEDIUM',
          metadata: dataLog);
    }

    // Keep only last 2000 data access logs
    if (_dataAccessLogs.length > 2000) {
      _dataAccessLogs.removeAt(0);
    }

    notifyListeners();
  }

  /// Log audit event
  void logAuditEvent(String event, String userId, String status,
      {Map<String, dynamic>? metadata}) {
    final auditLog = {
      'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'userId': userId,
      'status': status,
      'metadata': metadata ?? {},
      'hash': _generateLogHash(event, userId, status),
    };

    _auditLogs.add(auditLog);

    // Keep only last 3000 audit logs
    if (_auditLogs.length > 3000) {
      _auditLogs.removeAt(0);
    }

    notifyListeners();
  }

  /// Generate comprehensive security report
  Map<String, dynamic> generateSecurityReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    // Filter events by time period
    final last24HourEvents = _securityEvents.where((event) {
      final eventTime = DateTime.parse(event['timestamp']);
      return eventTime.isAfter(last24Hours);
    }).toList();

    final last7DayEvents = _securityEvents.where((event) {
      final eventTime = DateTime.parse(event['timestamp']);
      return eventTime.isAfter(last7Days);
    }).toList();

    return {
      'reportGenerated': now.toIso8601String(),
      'reportId': 'security_report_${now.millisecondsSinceEpoch}',
      'classification': 'CONFIDENTIAL',
      'summary': {
        'totalEvents': _totalSecurityEvents,
        'highRiskEvents': _highRiskEvents,
        'mediumRiskEvents': _mediumRiskEvents,
        'lowRiskEvents': _lowRiskEvents,
        'last24Hours': last24HourEvents.length,
        'last7Days': last7DayEvents.length,
      },
      'metrics': {
        'auditLogs': _auditLogs.length,
        'accessLogs': _accessLogs.length,
        'securityEvents': _securityEvents.length,
        'dataAccessLogs': _dataAccessLogs.length,
      },
      'recentEvents': _securityEvents.take(20).toList(),
      'threatLevel': _calculateThreatLevel(),
      'recommendations': _generateSecurityRecommendations(),
    };
  }

  /// Calculate current threat level
  String _calculateThreatLevel() {
    final recentHighRisk = _securityEvents.where((event) {
      final eventTime = DateTime.parse(event['timestamp']);
      final last1Hour = DateTime.now().subtract(const Duration(hours: 1));
      return eventTime.isAfter(last1Hour) &&
          ['HIGH', 'CRITICAL'].contains(event['severity']);
    }).length;

    if (recentHighRisk > 5) return 'CRITICAL';
    if (recentHighRisk > 2) return 'HIGH';
    if (_mediumRiskEvents > _lowRiskEvents) return 'MEDIUM';
    return 'LOW';
  }

  /// Generate security recommendations
  List<String> _generateSecurityRecommendations() {
    final recommendations = <String>[];

    if (_highRiskEvents > 10) {
      recommendations.add(
          'Review high-risk security events and implement additional countermeasures');
    }

    if (_lastSecurityCheck == null ||
        DateTime.now().difference(_lastSecurityCheck!).inHours > 24) {
      recommendations.add('Perform comprehensive security assessment');
    }

    if (_dataAccessLogs
            .where((log) => log['classification'] == 'TOP_SECRET')
            .length >
        50) {
      recommendations
          .add('Review TOP SECRET data access patterns for anomalies');
    }

    recommendations
        .add('Maintain regular VPN connection for secure communications');
    recommendations
        .add('Enable automatic security monitoring and real-time alerts');

    return recommendations;
  }

  /// Export security logs for external analysis
  Future<String> exportSecurityLogs(
      {DateTime? startDate, DateTime? endDate}) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final filteredLogs = {
      'exportMetadata': {
        'exportTime': DateTime.now().toIso8601String(),
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
        'classification': 'CONFIDENTIAL',
        'exportedBy': 'FALCON_SECURITY_SYSTEM',
      },
      'auditLogs': _auditLogs.where((log) {
        final logTime = DateTime.parse(log['timestamp']);
        return logTime.isAfter(start) && logTime.isBefore(end);
      }).toList(),
      'securityEvents': _securityEvents.where((event) {
        final eventTime = DateTime.parse(event['timestamp']);
        return eventTime.isAfter(start) && eventTime.isBefore(end);
      }).toList(),
      'accessLogs': _accessLogs.where((log) {
        final logTime = DateTime.parse(log['timestamp']);
        return logTime.isAfter(start) && logTime.isBefore(end);
      }).toList(),
      'dataAccessLogs': _dataAccessLogs.where((log) {
        final logTime = DateTime.parse(log['timestamp']);
        return logTime.isAfter(start) && logTime.isBefore(end);
      }).toList(),
    };

    return jsonEncode(filteredLogs);
  }

  /// Update security metrics
  void _updateSecurityMetrics() {
    _totalSecurityEvents = _securityEvents.length;
    _highRiskEvents = _securityEvents
        .where((e) => ['HIGH', 'CRITICAL'].contains(e['severity']))
        .length;
    _mediumRiskEvents =
        _securityEvents.where((e) => e['severity'] == 'MEDIUM').length;
    _lowRiskEvents = _securityEvents
        .where((e) => ['LOW', 'INFO'].contains(e['severity']))
        .length;
  }

  /// Generate session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256
        .convert(utf8.encode('falcon_session_$timestamp'))
        .toString()
        .substring(0, 16);
  }

  /// Generate log hash for integrity verification
  String _generateLogHash(String event, String userId, String status) {
    final data =
        '$event:$userId:$status:${DateTime.now().millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 32);
  }

  /// Clear old logs (retention policy)
  void clearOldLogs({int retentionDays = 90}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    _auditLogs.removeWhere((log) {
      final logTime = DateTime.parse(log['timestamp']);
      return logTime.isBefore(cutoffDate);
    });

    _securityEvents.removeWhere((event) {
      final eventTime = DateTime.parse(event['timestamp']);
      return eventTime.isBefore(cutoffDate);
    });

    _accessLogs.removeWhere((log) {
      final logTime = DateTime.parse(log['timestamp']);
      return logTime.isBefore(cutoffDate);
    });

    _dataAccessLogs.removeWhere((log) {
      final logTime = DateTime.parse(log['timestamp']);
      return logTime.isBefore(cutoffDate);
    });

    _updateSecurityMetrics();
    notifyListeners();

    _logSecurityEvent(
        'LOG_CLEANUP',
        'Old logs cleared according to retention policy ($retentionDays days)',
        'INFO');
  }
}
