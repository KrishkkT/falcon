import 'dart:async';
// ignore: duplicate_import
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database_manager.dart';
// ignore: unused_import
import 'package:sqflite/sqflite.dart';

class AutoDeleteService extends ChangeNotifier {
  static const int _DEFAULT_AUTO_DELETE_HOURS = 24; // Default 24 hours
  static const int _CLEANUP_INTERVAL_MINUTES = 30; // Check every 30 minutes

  bool _isEnabled = false;
  int _autoDeleteHours = _DEFAULT_AUTO_DELETE_HOURS;
  DateTime? _lastCleanupTime;
  Timer? _cleanupTimer;

  bool get isEnabled => _isEnabled;
  int get autoDeleteHours => _autoDeleteHours;
  DateTime? get lastCleanupTime => _lastCleanupTime;

  /// Enable auto-delete functionality
  void enableAutoDelete({int hours = _DEFAULT_AUTO_DELETE_HOURS}) {
    _isEnabled = true;
    _autoDeleteHours = hours;
    _startCleanupTimer();
    debugPrint('Auto-delete enabled for messages older than $hours hours');
    notifyListeners();
  }

  /// Disable auto-delete functionality
  void disableAutoDelete() {
    _isEnabled = false;
    _stopCleanupTimer();
    debugPrint('Auto-delete disabled');
    notifyListeners();
  }

  /// Set auto-delete duration
  void setAutoDeleteDuration(int hours) {
    _autoDeleteHours = hours;
    debugPrint('Auto-delete duration set to $hours hours');
    notifyListeners();
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _stopCleanupTimer();

    _cleanupTimer = Timer.periodic(
      const Duration(minutes: _CLEANUP_INTERVAL_MINUTES),
      (_) => _cleanupExpiredMessages(),
    );

    debugPrint('Auto-delete cleanup timer started');
  }

  /// Stop cleanup timer
  void _stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    debugPrint('Auto-delete cleanup timer stopped');
  }

  /// Cleanup expired messages
  Future<void> _cleanupExpiredMessages() async {
    if (!_isEnabled) return;

    try {
      final cutoffTime =
          DateTime.now().subtract(Duration(hours: _autoDeleteHours));
      final cutoffTimestamp =
          cutoffTime.millisecondsSinceEpoch ~/ 1000; // Convert to seconds

      debugPrint(
          'Cleaning up messages older than $cutoffTime (timestamp: $cutoffTimestamp)');

      final db = await DatabaseManager.database;

      // Delete expired messages
      final deletedMessages = await db.delete(
        'messages',
        where: 'timestamp < ?',
        whereArgs: [cutoffTimestamp],
      );

      // Update conversations to remove references to deleted messages
      await db.rawUpdate('''
        UPDATE conversations 
        SET last_message_id = NULL, last_message_text = NULL, last_message_timestamp = NULL
        WHERE last_message_id IN (
          SELECT id FROM messages WHERE timestamp < ?
        )
      ''', [cutoffTimestamp]);

      if (deletedMessages > 0) {
        debugPrint('Deleted $deletedMessages expired messages');
        _lastCleanupTime = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error during auto-delete cleanup: $e');
    }
  }

  /// Manually trigger cleanup
  Future<void> manualCleanup() async {
    await _cleanupExpiredMessages();
  }

  /// Get count of expired messages
  Future<int> getExpiredMessageCount() async {
    if (!_isEnabled) return 0;

    try {
      final cutoffTime =
          DateTime.now().subtract(Duration(hours: _autoDeleteHours));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch ~/ 1000;

      final db = await DatabaseManager.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM messages WHERE timestamp < ?',
        [cutoffTimestamp],
      );

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting expired message count: $e');
      return 0;
    }
  }

  /// Dispose service and clean up resources
  @override
  void dispose() {
    _stopCleanupTimer();
    super.dispose();
  }
}
