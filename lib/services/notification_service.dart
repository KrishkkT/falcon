import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService extends ChangeNotifier with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(String conversationId)? _onSelectNotificationCallback;
  bool _isAppInBackground = false;

  bool get isInitialized => _initialized;
  bool get isAppInBackground => _isAppInBackground;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Add app lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification,
      );

      _initialized = true;
      notifyListeners();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Track app lifecycle state for notification handling
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isAppInBackground = true;
      debugPrint('App went to background');
    } else if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      debugPrint('App came to foreground');
    }

    notifyListeners();
  }

  /// Set callback for handling notification taps
  void setOnSelectNotificationCallback(
      Function(String conversationId) callback) {
    _onSelectNotificationCallback = callback;
  }

  /// Handle notification tap
  Future<void> _onSelectNotification(
      NotificationResponse notificationResponse) async {
    debugPrint(
        'Notification tapped with payload: ${notificationResponse.payload}');

    // Handle notification tap - navigate to appropriate screen
    if (notificationResponse.payload != null &&
        _onSelectNotificationCallback != null) {
      _onSelectNotificationCallback!(notificationResponse.payload!);
    }
  }

  /// Show local notification
  Future<void> showLocalNotification(
    String title,
    String body, {
    String? payload,
    int? id,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'falcon_chat_channel',
        'Falcon Chat',
        channelDescription: 'Falcon Chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        // Add notification category for better handling
        category: AndroidNotificationCategory.message,
        // Enable heads-up notification
        fullScreenIntent: true,
        // Set notification icon
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await _localNotificationsPlugin.show(
        id ?? DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Show message notification that opens specific chat
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String conversationId,
    String? senderId,
  }) async {
    // Only show notification if app is in background
    if (_isAppInBackground) {
      await showLocalNotification(
        senderName,
        message,
        payload:
            conversationId, // Use conversationId as payload to open correct chat
        id: senderId?.hashCode ?? conversationId.hashCode,
      );
    } else {
      debugPrint(
          'App is in foreground, skipping notification for: $senderName - $message');
    }
  }

  /// Show foreground notification (for when app is active)
  Future<void> showForegroundNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    // Only show notification if app is in foreground
    if (!_isAppInBackground) {
      await showLocalNotification(
        title,
        body,
        payload: payload,
        id: id,
      );
    } else {
      debugPrint(
          'App is in background, skipping foreground notification: $title');
    }
  }

  /// Schedule a notification
  Future<void> scheduleNotification(
    String title,
    String body, {
    required DateTime scheduledTime,
    String? payload,
    int? id,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'falcon_chat_channel',
        'Falcon Chat',
        channelDescription: 'Falcon Chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await _localNotificationsPlugin.zonedSchedule(
        id ?? DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  /// Handle VPN state changes for notifications
  void handleVpnStateChange(bool isVpnActive) {
    debugPrint('VPN state changed to: $isVpnActive');
    // In a real implementation, you might want to adjust notification settings
    // based on VPN state, but for local notifications this isn't necessary
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _localNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<void> requestNotificationPermissions() async {
    try {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }
}
