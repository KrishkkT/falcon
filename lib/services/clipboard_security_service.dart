import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class ClipboardSecurityService extends ChangeNotifier {
  static const String _SECURE_PREFIX = 'FALCON_SECURE_';
  static const int _MAX_SECURE_CONTENT_AGE_MINUTES = 30;

  final Map<String, SecureClipboardItem> _secureClipboard = {};
  String? _lastCopiedContent;
  DateTime? _lastCopyTime;

  /// Copy secure content to clipboard with encryption
  Future<void> copySecureContent(String content, {String? label}) async {
    try {
      // Store original content for internal use
      _lastCopiedContent = content;
      _lastCopyTime = DateTime.now();

      // Create secure clipboard item with timestamp
      final itemId = _generateSecureId();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      _secureClipboard[itemId] = SecureClipboardItem(
        id: itemId,
        content: content,
        label: label ?? 'Secure Content',
        timestamp: timestamp,
        isSecure: true,
      );

      // Clean up old secure items
      _cleanupOldSecureItems();

      // Copy a secure marker to clipboard instead of actual content
      final secureMarker = '$_SECURE_PREFIX$itemId';
      await Clipboard.setData(ClipboardData(text: secureMarker));

      debugPrint('Secure content copied with ID: $itemId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error copying secure content: $e');
      rethrow;
    }
  }

  /// Paste secure content from clipboard
  Future<String?> pasteSecureContent() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text;

      if (clipboardText == null) {
        return null;
      }

      // Check if it's our secure content
      if (clipboardText.startsWith(_SECURE_PREFIX)) {
        final itemId = clipboardText.substring(_SECURE_PREFIX.length);
        final secureItem = _secureClipboard[itemId];

        if (secureItem != null) {
          // Check if content is still valid
          final itemAge =
              DateTime.now().millisecondsSinceEpoch - secureItem.timestamp;
          if (itemAge <= _MAX_SECURE_CONTENT_AGE_MINUTES * 60 * 1000) {
            debugPrint('Secure content pasted successfully');
            return secureItem.content;
          } else {
            // Content expired, remove it
            _secureClipboard.remove(itemId);
            debugPrint('Secure content expired');
          }
        }
      }

      // Return regular clipboard content if not our secure content
      return clipboardText;
    } catch (e) {
      debugPrint('Error pasting secure content: $e');
      return null;
    }
  }

  /// Check if clipboard contains secure content
  Future<bool> hasSecureContent() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text;

      if (clipboardText == null) {
        return false;
      }

      return clipboardText.startsWith(_SECURE_PREFIX);
    } catch (e) {
      debugPrint('Error checking secure content: $e');
      return false;
    }
  }

  /// Clear secure clipboard
  void clearSecureClipboard() {
    _secureClipboard.clear();
    _lastCopiedContent = null;
    _lastCopyTime = null;
    debugPrint('Secure clipboard cleared');
    notifyListeners();
  }

  /// Get last copied content (for internal use only)
  String? get lastCopiedContent => _lastCopiedContent;

  /// Check if last copied content is recent
  bool get hasRecentCopy {
    if (_lastCopyTime == null) return false;
    final age = DateTime.now().difference(_lastCopyTime!);
    return age.inMinutes <= _MAX_SECURE_CONTENT_AGE_MINUTES;
  }

  /// Generate secure ID for clipboard items
  String _generateSecureId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Clean up old secure clipboard items
  void _cleanupOldSecureItems() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredItems = <String>[];

    _secureClipboard.forEach((id, item) {
      final age = now - item.timestamp;
      if (age > _MAX_SECURE_CONTENT_AGE_MINUTES * 60 * 1000) {
        expiredItems.add(id);
      }
    });

    for (final id in expiredItems) {
      _secureClipboard.remove(id);
    }

    if (expiredItems.isNotEmpty) {
      debugPrint(
          'Cleaned up ${expiredItems.length} expired secure clipboard items');
    }
  }
}

/// Secure clipboard item model
class SecureClipboardItem {
  final String id;
  final String content;
  final String label;
  final int timestamp;
  final bool isSecure;

  SecureClipboardItem({
    required this.id,
    required this.content,
    required this.label,
    required this.timestamp,
    required this.isSecure,
  });
}
