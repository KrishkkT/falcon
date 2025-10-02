import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [$level] $tag: $message${stackTrace != null ? '\n$stackTrace' : ''}';
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'tag': tag,
      'message': message,
      'stackTrace': stackTrace,
    };
  }

  static LogEntry fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: json['level'],
      tag: json['tag'],
      message: json['message'],
      stackTrace: json['stackTrace'],
    );
  }
}

class LogService extends ChangeNotifier {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000; // Keep only the last 1000 logs
  File? _logFile;

  /// Initialize log service
  Future<void> initialize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final logDirectory =
          Directory(path.join(documentsDirectory.path, 'logs'));

      // Create logs directory if it doesn't exist
      if (!await logDirectory.exists()) {
        await logDirectory.create(recursive: true);
      }

      // Create log file with current date
      final now = DateTime.now();
      final filename =
          'falcon_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
      _logFile = File(path.join(logDirectory.path, filename));

      // Load existing logs from file
      await _loadLogsFromFile();

      debugPrint('Log service initialized with file: ${_logFile?.path}');
    } catch (e) {
      debugPrint('Error initializing log service: $e');
    }
  }

  /// Load logs from file
  Future<void> _loadLogsFromFile() async {
    if (_logFile == null || !await _logFile!.exists()) return;

    try {
      final content = await _logFile!.readAsString();
      final lines = content.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        // Parse log entry from string (simplified parsing)
        try {
          // This is a simplified parser - in a real implementation, you'd want more robust parsing
          final parts = line.split(' ');
          if (parts.length >= 4) {
            final timestampStr = parts[0];
            final level = parts[1].replaceAll('[', '').replaceAll(']', '');
            final tag = parts[2].replaceAll(':', '');
            final message = parts.sublist(3).join(' ');

            final logEntry = LogEntry(
              timestamp: DateTime.parse(timestampStr),
              level: level,
              tag: tag,
              message: message,
            );

            _logs.add(logEntry);
          }
        } catch (e) {
          // Skip malformed log entries
          debugPrint('Skipping malformed log entry: $line');
        }
      }

      // Keep only recent logs
      if (_logs.length > _maxLogs) {
        _logs.removeRange(0, _logs.length - _maxLogs);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading logs from file: $e');
    }
  }

  /// Add a log entry
  void log({
    required String level,
    required String tag,
    required String message,
    String? stackTrace,
  }) {
    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      stackTrace: stackTrace,
    );

    // Add to in-memory logs
    _logs.add(logEntry);

    // Keep only the last _maxLogs entries
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Write to file
    _writeLogToFile(logEntry);

    // Notify listeners for real-time updates
    notifyListeners();

    // Also print to console for debugging
    if (kDebugMode) {
      print(logEntry.toString());
    }
  }

  /// Write log entry to file
  Future<void> _writeLogToFile(LogEntry logEntry) async {
    if (_logFile == null) return;

    try {
      await _logFile!
          .writeAsString('${logEntry.toString()}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Error writing log to file: $e');
    }
  }

  /// Log debug message
  void debug(String tag, String message) {
    log(level: 'DEBUG', tag: tag, message: message);
  }

  /// Log info message
  void info(String tag, String message) {
    log(level: 'INFO', tag: tag, message: message);
  }

  /// Log warning message
  void warn(String tag, String message, [String? stackTrace]) {
    log(level: 'WARN', tag: tag, message: message, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String tag, String message, [String? stackTrace]) {
    log(level: 'ERROR', tag: tag, message: message, stackTrace: stackTrace);
  }

  /// Get all logs
  List<LogEntry> getLogs() {
    return List.unmodifiable(_logs);
  }

  /// Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(String level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs within a time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs
        .where((log) =>
            log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList();
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _logs.clear();

    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }

    notifyListeners();
    debugPrint('Logs cleared');
  }

  /// Export logs to a file
  Future<String?> exportLogs() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final exportDirectory =
          Directory(path.join(documentsDirectory.path, 'logs_export'));

      // Create export directory if it doesn't exist
      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      // Create export file with timestamp
      final now = DateTime.now();
      final filename = 'falcon_logs_${now.millisecondsSinceEpoch}.txt';
      final exportFile = File(path.join(exportDirectory.path, filename));

      // Write all logs to export file
      final buffer = StringBuffer();
      for (final log in _logs) {
        buffer.writeln(log.toString());
      }

      await exportFile.writeAsString(buffer.toString());

      return exportFile.path;
    } catch (e) {
      debugPrint('Error exporting logs: $e');
      return null;
    }
  }

  /// Get log file path
  String? get logFilePath => _logFile?.path;

  /// Get log count
  int get logCount => _logs.length;
}
