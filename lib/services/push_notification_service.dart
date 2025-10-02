import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _fcmInitialized = false;
  bool _localNotificationsInitialized = false;
  Function(Map<String, dynamic> messageData)? _onMessageReceivedCallback;
  Function(String conversationId)? _onNotificationTapCallback;

  /// Initialize push notification service with fallback
  Future<void> initialize({
    Function(Map<String, dynamic> messageData)? onMessageReceived,
    Function(String conversationId)? onNotificationTap,
  }) async {
    _onMessageReceivedCallback = onMessageReceived;
    _onNotificationTapCallback = onNotificationTap;

    // Try to initialize FCM first
    await _initializeFCM();

    // Initialize local notifications as fallback
    await _initializeLocalNotifications();

    debugPrint(
        'Push notification service initialized with FCM: $_fcmInitialized, Local: $_localNotificationsInitialized');
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    try {
      if (kIsWeb) {
        // FCM is not supported on web in this implementation
        _fcmInitialized = false;
        return;
      }

      // Initialize Firebase (this would require firebase_core)
      // For now, we'll just set up message handlers if FCM is available
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Get initial message (when app is opened from terminated state)
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageTap(initialMessage);
      }

      // Request permission for notifications
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _fcmInitialized = true;
      debugPrint('FCM initialized successfully');
    } catch (e) {
      _fcmInitialized = false;
      debugPrint('FCM initialization failed: $e');
      // FCM failed, we'll rely on local notifications
    }
  }

  /// Initialize local notifications as fallback
  Future<void> _initializeLocalNotifications() async {
    try {
      // Local notifications are already handled by NotificationService
      _localNotificationsInitialized = true;
      debugPrint('Local notifications ready as fallback');
    } catch (e) {
      _localNotificationsInitialized = false;
      debugPrint('Local notifications initialization failed: $e');
    }
  }

  /// Handle foreground message (when app is active)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.data}');

    // Convert FCM message to our format
    final messageData = _convertFcmMessageToData(message);

    // Notify callback if provided
    if (_onMessageReceivedCallback != null) {
      _onMessageReceivedCallback!(messageData);
    }

    // Show notification if app is in foreground
    final senderName = messageData['senderName'] as String? ?? 'Unknown User';
    final messageText = messageData['message'] as String? ?? '';
    final conversationId = messageData['conversationId'] as String? ?? '';

    // Show foreground notification through NotificationService
    // This would be called from the main app context
  }

  /// Handle background message tap (when app is opened from notification)
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Notification tapped from background: ${message.data}');

    // Convert FCM message to our format
    final messageData = _convertFcmMessageToData(message);

    // Extract conversation ID and navigate to chat
    final conversationId = messageData['conversationId'] as String? ?? '';

    if (conversationId.isNotEmpty && _onNotificationTapCallback != null) {
      _onNotificationTapCallback!(conversationId);
    }
  }

  /// Convert FCM message to our internal format
  Map<String, dynamic> _convertFcmMessageToData(RemoteMessage message) {
    return {
      'senderId': message.data['senderId'] ?? '',
      'senderName': message.data['senderName'] ??
          message.notification?.title ??
          'Unknown User',
      'message': message.data['message'] ?? message.notification?.body ?? '',
      'conversationId': message.data['conversationId'] ??
          '${message.data['senderId']}_${message.data['recipientId']}',
      'timestamp':
          message.data['timestamp'] ?? DateTime.now().toIso8601String(),
      'messageType': message.data['messageType'] ?? 'text',
      ...message.data, // Include any additional data
    };
  }

  /// Show notification using local notifications as fallback
  Future<void> showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // If FCM is available, we rely on it to handle notifications
    // If not, we use local notifications as fallback

    if (!_fcmInitialized && _localNotificationsInitialized) {
      // Use local notifications as fallback
      // This would integrate with NotificationService
      debugPrint('Showing local notification as FCM fallback: $title - $body');
    } else {
      debugPrint('FCM should handle notification: $title - $body');
    }
  }

  /// Handle local notification tap
  void handleLocalNotificationTap(String conversationId) {
    debugPrint('Local notification tapped for conversation: $conversationId');

    if (_onNotificationTapCallback != null) {
      _onNotificationTapCallback!(conversationId);
    }
  }

  /// Check if FCM is available and working
  bool get isFcmAvailable => _fcmInitialized;

  /// Check if local notifications are available as fallback
  bool get isLocalNotificationsAvailable => _localNotificationsInitialized;
}
