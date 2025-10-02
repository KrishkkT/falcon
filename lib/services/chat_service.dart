import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'network_config_service.dart';
import '../utils/network_utils.dart';
import '../utils/api_validator.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Add mime package for file type detection
import 'package:http_parser/http_parser.dart'; // Add http_parser for MediaType
import 'package:http_parser/http_parser.dart'; // Add http_parser for MediaType

class ChatService extends ChangeNotifier {
  // Base URLs for API calls - can be configured for remote access
  static String _baseUrl = NetworkConfigService.getBaseApiUrl();
  static String _wsUrl = NetworkConfigService.getWebSocketUrl();

  // Update base URLs for remote access
  static void updateBaseUrls(String newBaseUrl, String newWsUrl) {
    _baseUrl = newBaseUrl;
    _wsUrl = newWsUrl;
    debugPrint('Chat service base URLs updated to: $_baseUrl, $_wsUrl');
  }

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isReconnecting = false;
  String _connectionState =
      'disconnected'; // 'disconnected', 'connecting', 'connected', 'reconnecting', 'error'
  String? _authToken;
  AuthService? _authService;
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, List<Map<String, dynamic>>> _conversationMessages = {};
  final List<Map<String, dynamic>> _pendingMessages = [];
  final List<Map<String, dynamic>> _failedMessages = [];
  final List<Map<String, dynamic>> _contacts = [];
  Timer? _pendingMessageTimer;
  Timer? _offlineRetryTimer;
  int _reconnectAttempts = 0;
  bool _usingVpn = false;
  bool _isDisposed = false;
  bool _isOffline = false;

  // Offline message queuing
  static const Duration _offlineRetryInterval = Duration(seconds: 30);

  // Typing indicators
  final Map<String, bool> _userTypingStatus = {};
  final Map<String, Timer> _typingTimers = {};
  static const Duration _typingTimeout = Duration(seconds: 5);

  // User presence
  final Map<String, Map<String, dynamic>> _userPresence = {};
  static const Duration _presenceTimeout = Duration(minutes: 1);
  final Map<String, Timer> _presenceTimers = {};

  // File upload progress tracking
  final Map<String, double> _uploadProgress = {};
  final Map<String, bool> _uploadCancelled = {};

  // Rate limiting variables
  static const int _maxRequestsPerMinute = 30;
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];
  final Map<String, DateTime> _lastRequestTime = {};

  // Performance optimization for large message lists
  static const int _maxCachedMessagesPerConversation = 100;
  static const int _messageCacheCleanupThreshold = 150;

  // Message pagination
  final Map<String, int> _conversationPageOffsets = {};
  static const int _messagesPerPage = 50;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isReconnecting => _isReconnecting;
  bool get isOffline => _isOffline;
  String get connectionState => _connectionState;
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  List<Map<String, dynamic>> get contacts => List.unmodifiable(_contacts);
  List<Map<String, dynamic>> get pendingMessages =>
      List.unmodifiable(_pendingMessages);
  List<Map<String, dynamic>> get failedMessages =>
      List.unmodifiable(_failedMessages);
  bool get usingVpn => _usingVpn;

  // Typing indicators getter
  bool isUserTyping(String userId) => _userTypingStatus[userId] ?? false;

  // Add public getter for conversation messages
  Map<String, List<Map<String, dynamic>>> get conversationMessages =>
      Map.unmodifiable(_conversationMessages);

  /// Set auth service reference
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  /// Initialize chat service with authentication token
  void initialize(String authToken) {
    _authToken = authToken;
    _reconnectAttempts = 0; // Reset reconnect attempts
    _connectWebSocket();
    _sendPendingMessages(); // Send any pending messages when online

    // Start timer to periodically check for pending messages with rate limiting
    _pendingMessageTimer?.cancel();
    _pendingMessageTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_isConnected) {
        _sendPendingMessages();
      }
    });

    // Start offline retry timer
    _startOfflineRetryTimer();
  }

  /// Start offline retry timer
  void _startOfflineRetryTimer() {
    _offlineRetryTimer?.cancel();
    _offlineRetryTimer = Timer.periodic(_offlineRetryInterval, (timer) {
      if (!_isConnected && _pendingMessages.isNotEmpty) {
        debugPrint('Attempting to send pending messages while offline');
        _sendPendingMessages();
      }
    });
  }

  /// Set VPN status
  void setVpnStatus(bool isActive) {
    _usingVpn = isActive;
    debugPrint('VPN status updated: $isActive');
    // When VPN status changes, we need to reconnect WebSocket
    if (_authToken != null) {
      // Add a small delay to allow VPN to fully establish
      Future.delayed(const Duration(milliseconds: 1000), () {
        _reconnectWithTimeout();
      });
    }
  }

  /// Reconnect with timeout and fallback mechanism
  void _reconnectWithTimeout() {
    // Set a timer to detect if reconnection is taking too long
    Timer(const Duration(seconds: 15), () {
      if (_isReconnecting && !_isConnected) {
        debugPrint('Reconnection timeout, attempting fallback');
        _isReconnecting = false;
        _connectionState = 'error';
        _safeNotifyListeners();

        // Try to reconnect with different settings
        _reconnectAttempts = 0;
        _reconnect();
      }
    });

    _reconnect();
  }

  /// Get the appropriate WebSocket URL based on VPN status
  String _getWebSocketUrl() {
    // For local deployments, always use the configured WebSocket URL
    // The VPN should not affect WebSocket connections in development
    debugPrint('Getting WebSocket URL for deployment');
    debugPrint('VPN status: $_usingVpn');
    debugPrint(
        'Is local dev server: ${NetworkConfigService.isLocalDevelopmentServer()}');
    debugPrint(
        'Configured WebSocket URL: ${NetworkConfigService.getWebSocketUrl()}');

    return NetworkConfigService.getWebSocketUrl();
  }

  /// Safe notifyListeners that checks if the service is disposed
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('Error notifying listeners: $e');
      }
    }
  }

  /// Check if we can make a request based on rate limiting
  bool _canMakeRequest(String endpoint) {
    final now = DateTime.now();

    // Clean up old timestamps outside the window
    _requestTimestamps.removeWhere(
        (timestamp) => now.difference(timestamp) > _rateLimitWindow);

    // Check global rate limit
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      debugPrint('Global rate limit exceeded');
      return false;
    }

    // Check endpoint-specific rate limit (max 1 request per 5 seconds)
    final lastRequest = _lastRequestTime[endpoint];
    if (lastRequest != null &&
        now.difference(lastRequest) < Duration(seconds: 5)) {
      debugPrint('Endpoint rate limit exceeded for $endpoint');
      return false;
    }

    // Record this request
    _requestTimestamps.add(now);
    _lastRequestTime[endpoint] = now;
    return true;
  }

  /// Enhanced connect WebSocket with VPN/network change detection
  void _connectWebSocket() {
    try {
      // Disconnect existing socket if any
      _socket?.disconnect();
      _socket?.dispose();

      final wsUrl = _getWebSocketUrl();
      debugPrint('Connecting to Socket.IO: $wsUrl');
      debugPrint('Auth token: $_authToken');
      debugPrint('VPN status: $_usingVpn');

      // Set connecting status
      _isConnecting = true;
      _safeNotifyListeners();

      // Create Socket.IO connection with proper options
      _socket = IO.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': _authToken},
        'forceNew': true,
        'reconnection': true, // Enable automatic reconnection
        'reconnectionAttempts': 5,
        'reconnectionDelay': 3000,
        'reconnectionDelayMax': 10000,
        'timeout': 30000, // 30 seconds timeout
        'rejectUnauthorized': false,
        'secure': NetworkConfigService.isProduction(),
        'upgrade': false,
        'rememberUpgrade': true,
        'extraHeaders': {
          'Authorization': 'Bearer $_authToken',
        },
      });

      // Set up event listeners before connecting
      if (_socket != null) {
        _socket!.onConnect((_) {
          debugPrint('Socket.IO connected successfully');
          _isConnected = true;
          _isConnecting = false; // No longer connecting
          _isReconnecting = false;
          _connectionState = 'connected';
          _reconnectAttempts = 0; // Reset on successful connection
          _safeNotifyListeners();

          // Authenticate after connection
          if (_authToken != null) {
            _socket!.emit('authenticate', {'token': _authToken});
          }
        });

        _socket!.onDisconnect((_) {
          debugPrint('Socket.IO disconnected');
          _isConnected = false;
          _isConnecting = false; // No longer connecting
          _isReconnecting = true;
          _connectionState = 'disconnected';
          _reconnectAttempts++;
          _safeNotifyListeners();
          _reconnect();
        });

        _socket!.onError((error) {
          debugPrint('Socket.IO error: $error');
          _isConnected = false;
          _isConnecting = false; // No longer connecting
          _isReconnecting = true;
          _connectionState = 'error';
          _reconnectAttempts++;
          _safeNotifyListeners();
          _reconnect();
        });

        // Handle custom events
        _socket!.on('authenticated', (data) {
          debugPrint('Socket.IO authenticated successfully: $data');
          _isConnected = true;
          _isConnecting = false; // No longer connecting
          _isReconnecting = false;
          _connectionState = 'connected';
          _reconnectAttempts = 0; // Reset on successful authentication
          _safeNotifyListeners();

          // Send initial presence update
          updateOwnPresenceToOnline();
        });

        _socket!.on('authentication_error', (data) {
          debugPrint('Socket.IO authentication error: $data');
          _isConnected = false;
          _isConnecting = false; // No longer connecting
          _isReconnecting = false;
          _connectionState = 'error';
          _safeNotifyListeners();

          // If authentication fails, try to refresh token
          _refreshAuthToken();
        });

        _socket!.on('new_message', (data) {
          debugPrint('Received new_message event: $data');
          _handleNewMessage(data);
        });

        _socket!.on('message_sent', (data) {
          debugPrint('Received message_sent event: $data');
          _handleMessageSent(data);
        });

        _socket!.on('message_delivered', (data) {
          debugPrint('Received message_delivered event: $data');
          _handleMessageDelivered(data);
        });

        _socket!.on('message_read', (data) {
          debugPrint('Message read: $data');
          _handleMessageRead(data);
        });

        _socket!.on('user_typing', (data) {
          debugPrint('User typing: $data');
          _handleUserTyping(data);
        });

        _socket!.on('user_stopped_typing', (data) {
          debugPrint('User stopped typing: $data');
          _handleUserStoppedTyping(data);
        });

        _socket!.on('delete_message', (data) {
          debugPrint('Message deleted: $data');
          _handleMessageDeleted(data);
        });

        // Add handler for message_deleted from server
        _socket!.on('message_deleted', (data) {
          debugPrint('Message deleted notification: $data');
          _handleMessageDeleted(data);
        });

        // Add handler for message_deleted_confirm from server
        _socket!.on('message_deleted_confirm', (data) {
          debugPrint('Message deleted confirmation: $data');
          _handleMessageDeleted(data);
        });

        _socket!.on('error', (data) {
          debugPrint('Socket.IO server error: $data');
          _isConnecting = false; // No longer connecting
          _isReconnecting = true;
          _connectionState = 'error';
          _safeNotifyListeners();
        });

        _socket!.on('user_presence', (data) {
          debugPrint('User presence update: $data');
          _handleUserPresence(data);
        });

        _socket!.on('user_online', (data) {
          debugPrint('User online: $data');
          _handleUserPresence({
            ...data,
            'status': 'online',
            'isOnline': true,
          });
        });

        _socket!.on('user_offline', (data) {
          debugPrint('User offline: $data');
          _handleUserPresence({
            ...data,
            'status': 'offline',
            'isOnline': false,
          });
        });
      }

      // Connect to the server
      _socket!.connect();
    } catch (e) {
      debugPrint('Failed to connect Socket.IO: $e');
      _isConnected = false;
      _isConnecting = false; // No longer connecting
      _isReconnecting = true;
      _connectionState = 'error';
      _reconnectAttempts++;
      _safeNotifyListeners();
      _reconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = data is String ? jsonDecode(data) : data;

      debugPrint('Received Socket.IO message: $message');

      if (message is Map<String, dynamic> && message.containsKey('type')) {
        switch (message['type']) {
          case 'authenticated':
            debugPrint('Socket.IO authenticated successfully');
            _isConnected = true;
            _safeNotifyListeners();
            break;

          case 'authentication_error':
            debugPrint('Socket.IO authentication error: ${message['error']}');
            _isConnected = false;
            _safeNotifyListeners();
            break;

          case 'new_message':
            _handleNewMessage(message['data'] ?? message);
            break;

          case 'message_sent':
            _handleMessageSent(message['data'] ?? message);
            break;

          case 'user_typing':
            _handleUserTyping(message['data'] ?? message);
            break;

          case 'user_stopped_typing':
            _handleUserStoppedTyping(message['data'] ?? message);
            break;

          case 'message_read':
            _handleMessageRead(message['data'] ?? message);
            break;

          case 'error':
            debugPrint('Socket.IO error: ${message['error']}');
            break;

          default:
            debugPrint('Unknown Socket.IO message type: ${message['type']}');
        }
      } else {
        debugPrint('Received unexpected Socket.IO message format: $data');
      }
    } catch (e) {
      debugPrint('Error handling Socket.IO message: $e');
    }
  }

  /// Handle new incoming message
  void _handleNewMessage(Map<String, dynamic> messageData) {
    debugPrint('Handling new incoming message: $messageData');

    // Add to messages list
    _messages.add(messageData);

    // Update conversation cache with proper null safety
    final recipientId = messageData['recipientId'] as String?;
    final senderId = messageData['senderId'] as String?;
    final conversationId =
        messageData['conversationId'] as String? ?? '${senderId}_$recipientId';

    // Add to recipient's conversation cache
    if (recipientId != null) {
      if (!_conversationMessages.containsKey(recipientId)) {
        _conversationMessages[recipientId] = [];
      }
      _conversationMessages[recipientId]!.add(messageData);
    }

    // Add to sender's conversation cache
    if (senderId != null) {
      if (!_conversationMessages.containsKey(senderId)) {
        _conversationMessages[senderId] = [];
      }
      _conversationMessages[senderId]!.add(messageData);
    }

    // Save to local database for persistence
    _saveMessageToLocalDatabase(messageData);

    // Show notification for incoming messages (only if app is in background)
    if (recipientId != null && senderId != null) {
      _showMessageNotification(messageData);
    }

    _safeNotifyListeners();
  }

  /// Show notification for incoming message
  void _showMessageNotification(Map<String, dynamic> messageData) {
    try {
      final senderName = messageData['senderName'] as String? ?? 'Unknown User';
      final message = messageData['message'] as String? ?? '';
      final conversationId = messageData['conversationId'] as String? ??
          '${messageData['senderId']}_${messageData['recipientId']}';
      final senderId = messageData['senderId'] as String?;

      debugPrint('Showing notification: $senderName - $message');

      // In a real implementation, we would access the notification service here
      // This would require injecting the notification service or accessing it through a provider
      // For now, we'll just log that we should show a notification based on app state
    } catch (e) {
      debugPrint('Error showing message notification: $e');
    }
  }

  /// Handle confirmation of sent message
  void _handleMessageSent(Map<String, dynamic> messageData) {
    debugPrint('Handling sent message confirmation: $messageData');

    // Update local message with server data
    final tempId = messageData['tempId'] as String?;
    if (tempId != null) {
      final index = _messages.indexWhere((m) => m['tempId'] == tempId);
      if (index >= 0) {
        _messages[index] = messageData;
      } else {
        _messages.add(messageData);
      }

      // Remove from pending messages if it was pending
      _pendingMessages.removeWhere((m) => m['tempId'] == tempId);
    } else {
      // If no tempId, just add the message
      _messages.add(messageData);
    }

    // Update conversation cache with proper null safety
    final recipientId = messageData['recipientId'] as String?;
    if (recipientId != null) {
      if (!_conversationMessages.containsKey(recipientId)) {
        _conversationMessages[recipientId] = [];
      }
      try {
        // Check if message already exists in cache
        final existingIndex = tempId != null
            ? _conversationMessages[recipientId]!.indexWhere(
                (m) => m['tempId'] == tempId,
              )
            : -1;
        if (existingIndex >= 0) {
          _conversationMessages[recipientId]![existingIndex] = messageData;
        } else {
          _conversationMessages[recipientId]!.add(messageData);
        }
      } catch (e) {
        debugPrint('Error updating conversation cache for recipient: $e');
      }
    }

    // Save to local database for persistence
    _saveMessageToLocalDatabase(messageData);

    _safeNotifyListeners();
  }

  /// Send a message to a recipient (enhanced for media support)
  Future<void> sendMessage({
    required String recipientId,
    required String message,
    String messageType = 'text',
    File? mediaFile, // Add media file parameter
  }) async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    if (message.trim().isEmpty && mediaFile == null) {
      throw Exception('Message cannot be empty');
    }

    debugPrint('Sending message: "$message" to recipient: $recipientId');
    debugPrint(
      'Socket status - connected: $_isConnected, socket: ${_socket != null}',
    );

    // Create temporary message for immediate UI update with proper timestamp
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    // Use device time for timestamp instead of server time
    final currentTime = DateTime.now().toIso8601String();

    // Declare mediaUrl outside try block so it's accessible in catch block
    String? mediaUrl;

    // Determine message type based on file if provided
    if (mediaFile != null) {
      final extension = mediaFile.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        messageType = 'image';
      } else if (['mp4', 'mov', 'avi'].contains(extension)) {
        messageType = 'video';
      } else {
        messageType = 'document';
      }
    }

    final tempMessage = {
      'tempId': tempId,
      'senderId': _authService?.currentUser?['id'] ??
          'current_user', // Use actual user ID
      'recipientId': recipientId,
      'message': message,
      'messageType': messageType,
      'timestamp': currentTime,
      'deliveryStatus': 'sending',
      if (mediaFile != null) 'mediaPath': mediaFile.path,
    };

    _messages.add(tempMessage);
    _safeNotifyListeners();
    debugPrint('Added temporary message to UI');

    try {
      // Handle media file upload if provided
      if (mediaFile != null) {
        mediaUrl = await _uploadMediaFile(mediaFile, tempId);
        // Update message with media URL
        tempMessage['mediaUrl'] = mediaUrl;
        _safeNotifyListeners();
      }

      if (_socket != null && _isConnected) {
        // Send via Socket.IO for real-time delivery
        debugPrint('Sending message via Socket.IO');
        try {
          _socket!.emit('send_message', {
            'recipientId': recipientId,
            'message': message,
            'messageType': messageType,
            'tempId': tempId,
            'mediaUrl': mediaUrl, // Include media URL if available
            // Send device timestamp to server
            'timestamp': currentTime,
          });
          debugPrint('Socket.IO emit completed');
        } catch (e) {
          debugPrint('Error emitting send_message: $e');
        }
      } else {
        debugPrint(
            'Socket.IO not connected, queuing message for later delivery');
        // Store message in pending queue for later delivery (offline mode)
        final pendingMessage = {
          'recipientId': recipientId,
          'message': message,
          'messageType': messageType,
          'tempId': tempId,
          'timestamp': currentTime,
          'queuedAt': DateTime.now().toIso8601String(),
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        };

        _pendingMessages.add(pendingMessage);
        tempMessage['deliveryStatus'] = 'queued';
        _updateMessageStatus(tempId, 'queued');

        // Update offline status
        _isOffline = true;
        _safeNotifyListeners();

        debugPrint('Message queued for later delivery (offline mode)');

        // Try to send via HTTP API as fallback immediately
        try {
          await _sendMessageViaHttp(recipientId, message, messageType, tempId,
              mediaUrl: mediaUrl);
        } catch (e) {
          debugPrint('HTTP fallback failed: $e');
          // Message remains in pending queue for later delivery
        }
      }
    } catch (e) {
      // Update message status to failed
      _updateMessageStatus(tempId, 'failed');
      debugPrint('Message send failed: $e');
      // Show user-friendly error message
      if (e.toString().contains('Network')) {
        // When using VPN, don't throw exception, just queue the message
        if (_usingVpn) {
          print('VPN active, queuing message despite network error');
          // Store message in pending queue for later delivery (offline mode)
          final pendingMessage = {
            'recipientId': recipientId,
            'message': message,
            'messageType': messageType,
            'tempId': tempId,
            'timestamp': currentTime,
            'queuedAt': DateTime.now().toIso8601String(),
            if (mediaUrl != null) 'mediaUrl': mediaUrl,
          };

          _pendingMessages.add(pendingMessage);
          _updateMessageStatus(tempId, 'queued');
          _isOffline = true;
          _safeNotifyListeners();
          debugPrint(
              'Message queued for later delivery due to VPN network error');
          return;
        }
        throw Exception('Network error. Please check your connection.');
      } else if (e.toString().contains('timeout')) {
        // When using VPN, don't throw exception, just queue the message
        if (_usingVpn) {
          print('VPN active, queuing message despite timeout error');
          // Store message in pending queue for later delivery (offline mode)
          final pendingMessage = {
            'recipientId': recipientId,
            'message': message,
            'messageType': messageType,
            'tempId': tempId,
            'timestamp': currentTime,
            'queuedAt': DateTime.now().toIso8601String(),
            if (mediaUrl != null) 'mediaUrl': mediaUrl,
          };

          _pendingMessages.add(pendingMessage);
          _updateMessageStatus(tempId, 'queued');
          _isOffline = true;
          _safeNotifyListeners();
          debugPrint(
              'Message queued for later delivery due to VPN timeout error');
          return;
        }
        throw Exception('Connection timeout. Please try again.');
      } else {
        // When using VPN, don't throw exception, just queue the message
        if (_usingVpn) {
          print('VPN active, queuing message despite unknown error');
          // Store message in pending queue for later delivery (offline mode)
          final pendingMessage = {
            'recipientId': recipientId,
            'message': message,
            'messageType': messageType,
            'tempId': tempId,
            'timestamp': currentTime,
            'queuedAt': DateTime.now().toIso8601String(),
            if (mediaUrl != null) 'mediaUrl': mediaUrl,
          };

          _pendingMessages.add(pendingMessage);
          _updateMessageStatus(tempId, 'queued');
          _isOffline = true;
          _safeNotifyListeners();
          debugPrint(
              'Message queued for later delivery due to VPN unknown error');
          return;
        }
        throw Exception('Failed to send message. Please try again.');
      }
    }
  }

  /// Upload media file to server with progress tracking
  Future<String> _uploadMediaFile(File file, String tempId) async {
    try {
      // Check if upload was cancelled
      if (isUploadCancelled(tempId)) {
        throw Exception('Upload cancelled');
      }

      final baseUrl = getEffectiveBaseUrl();
      final url = Uri.parse('$baseUrl/upload/media');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $_authToken';

      // Detect file type
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileExtension = file.path.split('.').last;

      // Add file to request with progress tracking
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: 'media_$tempId.$fileExtension',
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // Add metadata
      request.fields['tempId'] = tempId;
      request.fields['fileType'] =
          mimeType.split('/')[0]; // image, video, application, etc.

      // Send request and track progress
      final response = await request.send();

      // Process response
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        return responseData['url'] ?? responseData['mediaUrl'] ?? '';
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Media upload error: $e');
      rethrow;
    }
  }

  /// Send message via HTTP API (fallback) with media support
  Future<void> _sendMessageViaHttp(
    String recipientId,
    String message,
    String messageType,
    String tempId, {
    String? mediaUrl,
  }) async {
    // Check rate limit before making request
    if (!_canMakeRequest('/chats/$recipientId/messages')) {
      throw Exception(
          'Rate limit exceeded. Please wait before sending another message.');
    }

    try {
      final effectiveBaseUrl = getEffectiveBaseUrl();
      debugPrint(
        'Sending message via HTTP API to: $effectiveBaseUrl/chats/$recipientId/messages',
      );

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10)
        ..userAgent = 'FalconChat/1.0';

      final uri = Uri.parse('$effectiveBaseUrl/chats/$recipientId/messages');
      final request = await client.postUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Connection', 'keep-alive');
      request.headers.set('Accept', 'application/json');

      final body = jsonEncode({
        'message': message,
        'messageType': messageType,
        'tempId': tempId,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      });

      debugPrint('HTTP request body: $body');

      request.write(body);

      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );

      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('HTTP message send response status: ${response.statusCode}');
      debugPrint('HTTP message send response body: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        debugPrint('HTTP message sent successfully: $responseData');
        _handleMessageSent(responseData['message']);
      } else if (response.statusCode == 401) {
        client.close();
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 429) {
        client.close();
        throw Exception(
            'Too many requests. Please wait before sending another message.');
      } else {
        client.close();
        // Even if HTTP fails, we still want to store the message for later delivery
        debugPrint(
          'HTTP send failed, but message will be delivered when recipient is online',
        );
        _updateMessageStatus(tempId, 'pending');
      }

      client.close();
    } catch (e) {
      debugPrint('HTTP message send failed: $e');
      // When using VPN, don't throw exception, just store message for later delivery
      if (_usingVpn) {
        print(
            'VPN active, storing message for later delivery despite HTTP send failure');
        _updateMessageStatus(tempId, 'pending');
        return;
      }
      throw Exception('Failed to send message. Please try again.');
    }
  }

  /// Handle message delivered event
  void _handleMessageDelivered(Map<String, dynamic> messageData) {
    debugPrint('Handling message delivered event: $messageData');

    // Update local message with server data
    final messageId = messageData['id'] as String?;
    if (messageId != null) {
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index >= 0) {
        _messages[index]['deliveryStatus'] = 'delivered';
      }
    }

    // Update conversation cache with proper null safety
    final recipientId = messageData['recipientId'] as String?;
    if (recipientId != null && _conversationMessages.containsKey(recipientId)) {
      try {
        final index = _conversationMessages[recipientId]!.indexWhere(
          (m) => m['id'] == messageId,
        );
        if (index >= 0) {
          _conversationMessages[recipientId]![index]['deliveryStatus'] =
              'delivered';
        }
      } catch (e) {
        debugPrint('Error updating delivery status in conversation cache: $e');
      }
    }

    _safeNotifyListeners();
  }

  /// Handle message read event
  void _handleMessageRead(Map<String, dynamic> messageData) {
    debugPrint('Handling message read event: $messageData');

    // Update local message with server data
    final messageId = messageData['id'] as String?;
    if (messageId != null) {
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index >= 0) {
        _messages[index]['read'] = true;
      }
    }

    // Update conversation cache with proper null safety
    final recipientId = messageData['recipientId'] as String?;
    if (recipientId != null && _conversationMessages.containsKey(recipientId)) {
      try {
        final index = _conversationMessages[recipientId]!.indexWhere(
          (m) => m['id'] == messageId,
        );
        if (index >= 0) {
          _conversationMessages[recipientId]![index]['read'] = true;
        }
      } catch (e) {
        debugPrint('Error updating read status in conversation cache: $e');
      }
    }

    _safeNotifyListeners();
  }

  /// Handle user typing event
  void _handleUserTyping(Map<String, dynamic> data) {
    debugPrint('Handling user typing event: $data');

    final userId = data['userId'] as String?;
    if (userId != null) {
      _userTypingStatus[userId] = true;

      // Reset typing timer if it exists
      _typingTimers[userId]?.cancel();

      // Set new typing timer
      _typingTimers[userId] = Timer(_typingTimeout, () {
        _userTypingStatus[userId] = false;
        _safeNotifyListeners();
      });

      _safeNotifyListeners();
    }
  }

  /// Handle user stopped typing event
  void _handleUserStoppedTyping(Map<String, dynamic> data) {
    debugPrint('Handling user stopped typing event: $data');

    final userId = data['userId'] as String?;
    if (userId != null) {
      _userTypingStatus[userId] = false;

      // Cancel typing timer if it exists
      _typingTimers[userId]?.cancel();

      _safeNotifyListeners();
    }
  }

  /// Handle message deleted event
  void _handleMessageDeleted(Map<String, dynamic> messageData) {
    debugPrint('Handling message deleted event: $messageData');

    // Remove message from local list
    final messageId = messageData['id'] as String?;
    if (messageId != null) {
      _messages.removeWhere((m) => m['id'] == messageId);
    }

    // Remove message from conversation cache with proper null safety
    final recipientId = messageData['recipientId'] as String?;
    if (recipientId != null && _conversationMessages.containsKey(recipientId)) {
      try {
        _conversationMessages[recipientId]!.removeWhere(
          (m) => m['id'] == messageId,
        );
      } catch (e) {
        debugPrint('Error removing message from conversation cache: $e');
      }
    }

    _safeNotifyListeners();
  }

  /// Handle user presence event
  void _handleUserPresence(Map<String, dynamic> data) {
    debugPrint('Handling user presence event: $data');

    final userId = data['userId'] as String?;
    if (userId != null) {
      _userPresence[userId] = data;

      // Reset presence timer if it exists
      _presenceTimers[userId]?.cancel();

      // Set new presence timer
      _presenceTimers[userId] = Timer(_presenceTimeout, () {
        _userPresence[userId] = {
          'userId': userId,
          'status': 'offline',
          'isOnline': false,
        };
        _safeNotifyListeners();
      });

      _safeNotifyListeners();
    }
  }

  /// Update own presence to online
  void updateOwnPresenceToOnline() {
    debugPrint('Updating own presence to online');

    if (_socket != null && _isConnected) {
      try {
        _socket!.emit('update_presence', {'status': 'online'});
      } catch (e) {
        debugPrint('Error emitting update_presence: $e');
      }
    }
  }

  /// Update own presence to offline
  void updateOwnPresenceToOffline() {
    debugPrint('Updating own presence to offline');

    if (_socket != null && _isConnected) {
      try {
        _socket!.emit('update_presence', {'status': 'offline'});
      } catch (e) {
        debugPrint('Error emitting update_presence: $e');
      }
    }
  }

  /// Get effective base URL based on VPN status
  String getEffectiveBaseUrl() {
    return NetworkConfigService.getEffectiveBaseUrl();
  }

  /// Send pending messages
  Future<void> _sendPendingMessages() async {
    debugPrint('Sending pending messages');

    if (_pendingMessages.isNotEmpty) {
      for (final message in _pendingMessages) {
        try {
          await _sendMessageViaHttp(
            message['recipientId'],
            message['message'],
            message['messageType'],
            message['tempId'],
            mediaUrl: message['mediaUrl'],
          );
          // Remove from pending if successful
          _pendingMessages.remove(message);
          debugPrint('Successfully sent pending message: ${message['tempId']}');
        } catch (e) {
          debugPrint('Failed to send pending message: $e');
          // Keep in pending for next attempt
        }
      }
    }
  }

  /// Reconnect WebSocket with state management
  void _reconnect() {
    if (_isReconnecting) {
      debugPrint('Already reconnecting, skipping');
      return;
    }

    debugPrint('Reconnecting WebSocket');
    _isReconnecting = true;
    _connectionState = 'reconnecting';
    _safeNotifyListeners();

    // Exponential backoff for reconnection attempts
    final delay = Duration(
        milliseconds: (1000 * math.pow(2, _reconnectAttempts)).toInt());

    // Add a delay before reconnecting to avoid rapid reconnection attempts
    Future.delayed(delay, () {
      if (!_isDisposed) {
        _connectWebSocket();
        _reconnectAttempts++;
      }
    });
  }

  /// Refresh authentication token
  void _refreshAuthToken() {
    debugPrint('Refreshing authentication token');

    if (_authService != null) {
      _authService!.refreshToken().then((newToken) {
        _authToken = newToken;
        _reconnect();
      }).catchError((error) {
        debugPrint('Failed to refresh token: $error');
      });
    }
  }

  /// Update message status
  void _updateMessageStatus(String tempId, String status) {
    debugPrint('Updating message status: $tempId to $status');

    final index = _messages.indexWhere((m) => m['tempId'] == tempId);
    if (index >= 0) {
      _messages[index]['deliveryStatus'] = status;
    }

    _safeNotifyListeners();
  }

  /// Cancel upload
  void cancelUpload(String tempId) {
    debugPrint('Cancelling upload: $tempId');

    _uploadCancelled[tempId] = true;
  }

  /// Check if upload is cancelled
  bool isUploadCancelled(String tempId) {
    return _uploadCancelled[tempId] ?? false;
  }

  /// Save message to local database
  void _saveMessageToLocalDatabase(Map<String, dynamic> messageData) {
    debugPrint('Saving message to local database: $messageData');

    // Implement local database saving logic here
  }

  /// Dispose chat service
  @override
  void dispose() {
    debugPrint('Disposing chat service');

    _socket?.disconnect();
    _socket?.dispose();
    _pendingMessageTimer?.cancel();
    _offlineRetryTimer?.cancel();

    // Cancel all typing timers
    _typingTimers.values.forEach((timer) => timer.cancel());
    _typingTimers.clear();

    // Cancel all presence timers
    _presenceTimers.values.forEach((timer) => timer.cancel());
    _presenceTimers.clear();

    _isDisposed = true;

    super.dispose();
  }

  /// Get upload progress for a message
  double getUploadProgress(String tempId) {
    return _uploadProgress[tempId] ?? 0.0;
  }

  /// Get index of last unread message in conversation
  int getLastUnreadMessageIndex(String conversationId) {
    try {
      final messages = _conversationMessages[conversationId];
      if (messages == null || messages.isEmpty) return -1;

      // Find the last message that is not read
      for (int i = messages.length - 1; i >= 0; i--) {
        final message = messages[i];
        // If message is from other user and not read, this is our target
        if (message['senderId'] != _authService?.currentUser?['id'] &&
            (message['read'] == null || message['read'] == false)) {
          return i;
        }
      }

      // If all messages are read, return -1
      return -1;
    } catch (e) {
      debugPrint('Error finding last unread message: $e');
      return -1;
    }
  }

  /// Retry sending a failed message
  Future<void> retrySendMessage(String tempId) async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    // Find the failed message
    final messageIndex = _messages.indexWhere((m) => m['tempId'] == tempId);
    if (messageIndex == -1) {
      throw Exception('Message not found');
    }

    final message = _messages[messageIndex];
    if (message['deliveryStatus'] != 'failed') {
      throw Exception('Message is not in failed state');
    }

    // Update message status to sending
    _updateMessageStatus(tempId, 'sending');

    try {
      final recipientId = message['recipientId'] as String;
      final messageText = message['message'] as String;
      final messageType = message['messageType'] as String? ?? 'text';
      final mediaUrl = message['mediaUrl'] as String?;

      // Try to send via Socket.IO first
      if (_socket != null && _isConnected) {
        debugPrint('Retrying message via Socket.IO');
        _socket!.emit('send_message', {
          'recipientId': recipientId,
          'message': messageText,
          'messageType': messageType,
          'tempId': tempId,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fallback to HTTP
        debugPrint('Retrying message via HTTP API');
        await _sendMessageViaHttp(recipientId, messageText, messageType, tempId,
            mediaUrl: mediaUrl);
      }
    } catch (e) {
      // Update message status back to failed
      _updateMessageStatus(tempId, 'failed');
      debugPrint('Message retry failed: $e');
      rethrow;
    }
  }

  /// Parse conversations data in isolate
  static Future<List<Map<String, dynamic>>> _parseConversationsData(
      String responseBody) async {
    final data = jsonDecode(responseBody);

    // Validate API response schema
    if (!ApiValidator.validateConversationsSchema(data)) {
      throw Exception('Invalid API response format for conversations');
    }

    // Ensure we're returning the correct data structure
    List<Map<String, dynamic>> conversations = [];
    if (data is Map<String, dynamic> && data.containsKey('conversations')) {
      final convList = data['conversations'];
      if (convList is List) {
        conversations = List<Map<String, dynamic>>.from(convList);
      }
    } else if (data is List) {
      conversations = List<Map<String, dynamic>>.from(data);
    }

    // Ensure each conversation has required fields and valid schema
    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];

      // Validate individual conversation schema
      if (!ApiValidator.validateConversationSchema(conversation)) {
        throw Exception('Invalid conversation data format');
      }

      conversations[i] = {
        'id': conversation['id'] ?? 'unknown_$i',
        'name': conversation['name'] ?? 'Unknown User',
        'avatar': conversation['avatar'] ?? '',
        'status': conversation['status'] ?? 'Available',
        'isOnline': conversation['isOnline'] ?? false,
        'unreadCount': conversation['unreadCount'] is int
            ? conversation['unreadCount']
            : 0,
        'lastMessage': conversation['lastMessage'],
        ...conversation, // Include any other fields
      };
    }

    return conversations;
  }

  /// Parse messages data in isolate
  static Future<List<Map<String, dynamic>>> _parseMessagesData(
      String responseBody) async {
    final data = jsonDecode(responseBody);

    // Validate API response schema
    if (!ApiValidator.validateMessagesSchema(data)) {
      throw Exception('Invalid API response format for messages');
    }

    List<Map<String, dynamic>> messagesList = [];

    if (data is Map<String, dynamic> && data.containsKey('messages')) {
      final msgList = data['messages'];
      if (msgList is List) {
        messagesList = List<Map<String, dynamic>>.from(msgList);
      }
    } else if (data is List) {
      messagesList = List<Map<String, dynamic>>.from(data);
    }

    // Ensure each message has required fields and proper timestamp format
    for (var i = 0; i < messagesList.length; i++) {
      final message = messagesList[i];

      // Validate individual message schema
      if (!ApiValidator.validateMessageSchema(message)) {
        throw Exception('Invalid message data format');
      }

      // Handle timestamp parsing properly
      String timestampStr = DateTime.now().toIso8601String();
      if (message['timestamp'] != null) {
        try {
          // Try to parse the timestamp, if it fails use current time
          DateTime.parse(message['timestamp'].toString());
          timestampStr = message['timestamp'].toString();
        } catch (e) {
          debugPrint('Error parsing timestamp: $e, using current time');
        }
      }

      messagesList[i] = {
        'id': message['id'] ?? 'msg_$i',
        'senderId': message['senderId'] ?? 'unknown',
        'recipientId': message['recipientId'] ?? 'unknown',
        'message': message['message'] ?? '',
        'messageType': message['messageType'] ?? 'text',
        'timestamp': timestampStr,
        'deliveryStatus': message['deliveryStatus'] ?? 'sent',
        ...message, // Include any other fields
      };
    }

    return messagesList;
  }

  /// Get conversations list with retry mechanism
  Future<List<Map<String, dynamic>>> getConversations(
      {int retryCount = 0}) async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    // Check rate limit before making request
    if (!_canMakeRequest('/conversations')) {
      throw Exception(
          'Rate limit exceeded. Please wait before refreshing conversations.');
    }

    try {
      final effectiveBaseUrl = getEffectiveBaseUrl();
      print('Using base URL for conversations: $effectiveBaseUrl');
      print('Current auth token: $_authToken');
      print('VPN status: $_usingVpn');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15) // Increased timeout
        ..idleTimeout = const Duration(seconds: 10)
        ..userAgent = 'FalconChat/1.0';

      final uri = Uri.parse('$effectiveBaseUrl/conversations');
      print('Making HTTP request to: $uri');

      final request = await client.getUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');

      // Increased timeout for VPN scenarios
      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
      final responseBody = await response.transform(utf8.decoder).join();

      print('Conversations response status: ${response.statusCode}');
      print('Conversations response body: $responseBody');

      if (response.statusCode == 200) {
        client.close();

        // Move heavy JSON parsing to compute isolate
        final conversations =
            await compute(_parseConversationsData, responseBody);

        print('Returning ${conversations.length} conversations');
        return conversations;
      } else if (response.statusCode == 401) {
        client.close();
        print('Authentication failed with status: ${response.statusCode}');
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 429) {
        client.close();
        print('Rate limit exceeded with status: ${response.statusCode}');
        throw Exception(
            'Too many requests from this IP. Please wait before trying again.');
      } else {
        client.close();
        print(
          'Failed to load conversations with status: ${response.statusCode}',
        );
        throw Exception('Failed to load conversations. Please try again.');
      }
    } on TimeoutException {
      print('Request timeout while loading conversations');
      // Retry mechanism for timeout errors
      if (retryCount < 2) {
        print('Retrying conversations load (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await getConversations(retryCount: retryCount + 1);
      }
      throw Exception('Request timeout. Please check your connection.');
    } on SocketException catch (e) {
      print('Socket error during conversations load: $e');
      if (e.message.contains('handshake') || e.message.contains('version')) {
        throw Exception(
          'SSL/TLS connection error. Please check server configuration.',
        );
      }
      // When VPN is active, we might need to handle local connections differently
      if (_usingVpn) {
        // Check if this is a local development server
        if (NetworkUtils.isLocalDevelopmentServer(_baseUrl)) {
          print('Detected local development server with active VPN');
          // With split tunneling, this should work now
          // Don't throw an exception immediately, try to retry
          if (retryCount < 2) {
            print(
                'Retrying conversations load with VPN (attempt ${retryCount + 1})');
            await Future.delayed(Duration(seconds: 3 * (retryCount + 1)));
            return await getConversations(retryCount: retryCount + 1);
          } else {
            // After retries, just return empty list instead of throwing exception
            print(
                'VPN connection failed after retries, returning empty conversations list');
            return [];
          }
        } else {
          print('VPN active with remote server, connection should work');
          // Try to retry before throwing exception
          if (retryCount < 2) {
            print(
                'Retrying conversations load with VPN (attempt ${retryCount + 1})');
            await Future.delayed(Duration(seconds: 3 * (retryCount + 1)));
            return await getConversations(retryCount: retryCount + 1);
          } else {
            // After retries, just return empty list instead of throwing exception
            print(
                'VPN connection failed after retries, returning empty conversations list');
            return [];
          }
        }
      }
      // Retry mechanism for network errors
      if (retryCount < 2) {
        print(
            'Retrying conversations load due to network error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await getConversations(retryCount: retryCount + 1);
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      print('Error loading conversations: $e');
      // Show user-friendly error message
      if (e.toString().contains('502') ||
          e.toString().contains('Bad Gateway')) {
        // Retry mechanism for server errors
        if (retryCount < 2) {
          print(
              'Retrying conversations load due to server error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await getConversations(retryCount: retryCount + 1);
        }
        // When using VPN, don't throw exception, just return empty list
        if (_usingVpn) {
          print(
              'VPN active, returning empty conversations list instead of throwing server error');
          return [];
        }
        throw Exception(
            'Server temporarily unavailable. Please try again later.');
      } else if (e.toString().contains('Network')) {
        // Retry mechanism for network errors
        if (retryCount < 2) {
          print(
              'Retrying conversations load due to network error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await getConversations(retryCount: retryCount + 1);
        }
        // When using VPN, don't throw exception, just return empty list
        if (_usingVpn) {
          print(
              'VPN active, returning empty conversations list instead of throwing network error');
          return [];
        }
        throw Exception('Network error. Please check your connection.');
      } else if (e.toString().contains('timeout')) {
        // Retry mechanism for timeout errors
        if (retryCount < 2) {
          print(
              'Retrying conversations load due to timeout (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await getConversations(retryCount: retryCount + 1);
        }
        // When using VPN, don't throw exception, just return empty list
        if (_usingVpn) {
          print(
              'VPN active, returning empty conversations list instead of throwing timeout error');
          return [];
        }
        throw Exception('Connection timeout. Please try again.');
      } else if (e.toString().contains('429')) {
        // When using VPN, don't throw exception, just return empty list
        if (_usingVpn) {
          print(
              'VPN active, returning empty conversations list instead of throwing rate limit error');
          return [];
        }
        throw Exception('Too many requests. Please wait before trying again.');
      } else {
        // Retry mechanism for other errors
        if (retryCount < 1) {
          print(
              'Retrying conversations load due to unknown error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await getConversations(retryCount: retryCount + 1);
        }
        // When using VPN, don't throw exception, just return empty list
        if (_usingVpn) {
          print(
              'VPN active, returning empty conversations list instead of throwing unknown error');
          return [];
        }
        throw Exception('Failed to load conversations. Please try again.');
      }
    }
  }

  /// Get messages between two users with pagination and retry mechanism
  Future<List<Map<String, dynamic>>> getMessages(String recipientId,
      {int page = 0, int retryCount = 0}) async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    // Check rate limit before making request
    if (!_canMakeRequest('/chats/$recipientId/messages')) {
      throw Exception(
          'Rate limit exceeded. Please wait before loading messages.');
    }

    try {
      // Check if we have cached messages for this conversation with proper null safety
      if (_conversationMessages.containsKey(recipientId) &&
          _conversationMessages[recipientId] != null) {
        final cachedMessages = _conversationMessages[recipientId]!;

        // If we're requesting the first page and have enough cached messages, return them
        if (page == 0 && cachedMessages.length >= _messagesPerPage) {
          // Return only the requested page
          final endIndex = (page + 1) * _messagesPerPage;
          if (endIndex <= cachedMessages.length) {
            print(
                'Returning cached messages for conversation: $recipientId (page $page)');
            return List<Map<String, dynamic>>.from(
                cachedMessages.sublist(page * _messagesPerPage, endIndex));
          }
        }

        // If we have all messages cached, return them
        if (cachedMessages.length <= _maxCachedMessagesPerConversation ||
            (page + 1) * _messagesPerPage > cachedMessages.length) {
          print('Returning all cached messages for conversation: $recipientId');
          return List<Map<String, dynamic>>.from(cachedMessages);
        }
      }

      final effectiveBaseUrl = getEffectiveBaseUrl();
      print('Using base URL for messages: $effectiveBaseUrl');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15) // Increased timeout
        ..idleTimeout = const Duration(seconds: 10);

      // Add pagination parameters
      final uri = Uri.parse(
          '$effectiveBaseUrl/chats/$recipientId/messages?page=$page&limit=$_messagesPerPage');
      print('Making HTTP request to: $uri');

      final request = await client.getUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
      final responseBody = await response.transform(utf8.decoder).join();

      print('Messages response status: ${response.statusCode}');
      print('Messages response body: $responseBody');

      if (response.statusCode == 200) {
        // Move heavy JSON parsing to compute isolate
        final messagesList = await compute(_parseMessagesData, responseBody);

        print('Loaded ${messagesList.length} messages from server');

        // Cache the messages for this conversation
        if (!_conversationMessages.containsKey(recipientId)) {
          _conversationMessages[recipientId] = [];
        }

        // For first page, replace cache; for subsequent pages, append
        if (page == 0) {
          _conversationMessages[recipientId] = messagesList;
        } else {
          _conversationMessages[recipientId]!.addAll(messagesList);
        }

        // Performance optimization: Clean up cache if it gets too large
        _cleanupMessageCache(recipientId);

        client.close();
        return messagesList;
      } else if (response.statusCode == 401) {
        client.close();
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 429) {
        client.close();
        throw Exception('Too many requests. Please wait before trying again.');
      } else {
        client.close();
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } on TimeoutException {
      // Retry mechanism for timeout errors
      if (retryCount < 2) {
        print('Retrying messages load (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await getMessages(recipientId,
            page: page, retryCount: retryCount + 1);
      }
      // When using VPN, don't throw exception, just return empty list
      if (_usingVpn) {
        print(
            'VPN active, returning empty messages list instead of throwing timeout error');
        return [];
      }
      throw Exception('Request timeout. Please check your connection.');
    } on SocketException catch (e) {
      print('Socket error during message load: $e');
      if (e.message.contains('handshake') || e.message.contains('version')) {
        throw Exception(
          'SSL/TLS connection error. Please check server configuration.',
        );
      }
      // Retry mechanism for network errors
      if (retryCount < 2) {
        print(
            'Retrying messages load due to network error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await getMessages(recipientId,
            page: page, retryCount: retryCount + 1);
      }
      // When using VPN, don't throw exception, just return empty list
      if (_usingVpn) {
        print(
            'VPN active, returning empty messages list instead of throwing network error');
        return [];
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      print('Error loading messages: $e');
      // Retry mechanism for other errors
      if (retryCount < 1) {
        print(
            'Retrying messages load due to unknown error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await getMessages(recipientId,
            page: page, retryCount: retryCount + 1);
      }
      // When using VPN, don't throw exception, just return empty list
      if (_usingVpn) {
        print(
            'VPN active, returning empty messages list instead of throwing error');
        return [];
      }
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  /// Clean up message cache to prevent memory issues
  void _cleanupMessageCache(String conversationId) {
    final messages = _conversationMessages[conversationId];
    if (messages != null && messages.length > _messageCacheCleanupThreshold) {
      // Keep only the most recent messages
      final startIndex = messages.length - _maxCachedMessagesPerConversation;
      if (startIndex > 0) {
        _conversationMessages[conversationId] =
            List<Map<String, dynamic>>.from(messages.sublist(startIndex));
        debugPrint('Cleaned up message cache for conversation $conversationId, '
            'kept ${_conversationMessages[conversationId]!.length} most recent messages');
      }
    }
  }

  /// Search for users with improved VPN handling
  Future<List<Map<String, dynamic>>> searchUsers(String query,
      {int retryCount = 0}) async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    // Validate search query
    if (query.trim().isEmpty) {
      return [];
    }

    if (query.trim().length < 2) {
      return [];
    }

    // Check rate limit before making request
    if (!_canMakeRequest('/users/search')) {
      throw Exception(
          'Rate limit exceeded. Please wait before searching again.');
    }

    try {
      final effectiveBaseUrl = getEffectiveBaseUrl();
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      final uri = Uri.parse(
          '$effectiveBaseUrl/users/search?q=${Uri.encodeQueryComponent(query)}');
      final request = await client.getUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        // Parse response with better error handling
        final data = json.decode(responseBody);
        if (data is Map<String, dynamic> && data.containsKey('users')) {
          final usersList = (data['users'] as List)
              .map((user) => user as Map<String, dynamic>)
              .toList();

          client.close();
          return usersList;
        } else {
          client.close();
          return [];
        }
      } else if (response.statusCode == 401) {
        client.close();
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 429) {
        client.close();
        throw Exception('Too many requests. Please wait before trying again.');
      } else {
        client.close();
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } on TimeoutException {
      // When using VPN, return cached results or empty list instead of throwing error
      if (_usingVpn) {
        print('VPN active, returning cached or empty results for user search');
        return [];
      }

      // Retry mechanism for timeout errors
      if (retryCount < 2) {
        print('Retrying user search (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await searchUsers(query, retryCount: retryCount + 1);
      }
      throw Exception('Request timeout. Please check your connection.');
    } on SocketException catch (e) {
      print('Socket error during user search: $e');

      // When using VPN, return cached results or empty list instead of throwing error
      if (_usingVpn) {
        print('VPN active, returning cached or empty results for user search');
        return [];
      }

      // Retry mechanism for network errors
      if (retryCount < 2) {
        print(
            'Retrying user search due to network error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await searchUsers(query, retryCount: retryCount + 1);
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      print('Error searching users: $e');

      // When using VPN, return cached results or empty list instead of throwing error
      if (_usingVpn) {
        print('VPN active, returning cached or empty results for user search');
        return [];
      }

      // Retry mechanism for other errors
      if (retryCount < 1) {
        print(
            'Retrying user search due to unknown error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await searchUsers(query, retryCount: retryCount + 1);
      }
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String recipientId) {
    if (_socket != null && _isConnected) {
      try {
        _socket!.emit('user_typing', {
          'recipientId': recipientId,
        });
      } catch (e) {
        debugPrint('Error emitting user_typing: $e');
      }
    }
  }

  /// Send stopped typing indicator
  void sendStoppedTypingIndicator(String recipientId) {
    if (_socket != null && _isConnected) {
      try {
        _socket!.emit('user_stopped_typing', {
          'recipientId': recipientId,
        });
      } catch (e) {
        debugPrint('Error emitting user_stopped_typing: $e');
      }
    }
  }

  /// Delete a message from the backend with retry mechanism
  Future<void> deleteMessage(String messageId, {int retryCount = 0}) async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    try {
      final effectiveBaseUrl = getEffectiveBaseUrl();
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      // Make HTTP DELETE request to remove the message from the backend
      debugPrint(
          'Deleting message: $messageId from $effectiveBaseUrl/chats/messages/$messageId');

      final uri = Uri.parse('$effectiveBaseUrl/chats/messages/$messageId');
      final request = await client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();

      if (response.statusCode != 200) {
        client.close();
        // If we get a 404, it might be because the message doesn't exist or wrong endpoint
        if (response.statusCode == 404) {
          debugPrint('Message not found, trying alternative endpoint');
          // Try alternative endpoint
          final altUri = Uri.parse('$effectiveBaseUrl/messages/$messageId');
          final altRequest = await client.deleteUrl(altUri);
          altRequest.headers.set('Authorization', 'Bearer $_authToken');
          altRequest.headers.set('Content-Type', 'application/json');

          final altResponse = await altRequest.close();
          if (altResponse.statusCode != 200) {
            client.close();
            throw Exception(
                'Failed to delete message: ${altResponse.statusCode}');
          }
        } else {
          client.close();
          throw Exception('Failed to delete message: ${response.statusCode}');
        }
      }

      // Remove the message from local cache
      _messages.removeWhere((m) =>
          m['id']?.toString() == messageId ||
          m['tempId']?.toString() == messageId);

      // Remove from conversation messages cache
      _conversationMessages.forEach((key, value) {
        value.removeWhere((m) =>
            m['id']?.toString() == messageId ||
            m['tempId']?.toString() == messageId);
      });

      // Notify other clients about the deletion via WebSocket
      if (_socket != null && _isConnected) {
        try {
          _socket!.emit('delete_message', {
            'messageId': messageId,
          });
        } catch (e) {
          debugPrint('Error emitting delete_message: $e');
        }
      }

      client.close();
      _safeNotifyListeners();
    } on SocketException catch (e) {
      debugPrint('Socket error during message deletion: $e');
      // Retry mechanism for network errors
      if (retryCount < 2) {
        debugPrint(
            'Retrying message deletion due to network error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await deleteMessage(messageId, retryCount: retryCount + 1);
      }
      // When using VPN, don't throw exception, just remove from local cache
      if (_usingVpn) {
        print(
            'VPN active, removing message from local cache despite network error');
        // Remove the message from local cache even if backend fails
        _messages.removeWhere((m) =>
            m['id']?.toString() == messageId ||
            m['tempId']?.toString() == messageId);

        // Remove from conversation messages cache
        _conversationMessages.forEach((key, value) {
          value.removeWhere((m) =>
              m['id']?.toString() == messageId ||
              m['tempId']?.toString() == messageId);
        });

        _safeNotifyListeners();
        return;
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      debugPrint('Error deleting message: $e');
      // Retry mechanism for other errors
      if (retryCount < 1) {
        debugPrint(
            'Retrying message deletion due to unknown error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await deleteMessage(messageId, retryCount: retryCount + 1);
      }
      // When using VPN, don't throw exception, just log and continue
      if (_usingVpn) {
        print('VPN active, continuing with message deletion despite error');
        // Remove the message from local cache even if backend fails
        _messages.removeWhere((m) =>
            m['id']?.toString() == messageId ||
            m['tempId']?.toString() == messageId);

        // Remove from conversation messages cache
        _conversationMessages.forEach((key, value) {
          value.removeWhere((m) =>
              m['id']?.toString() == messageId ||
              m['tempId']?.toString() == messageId);
        });

        _safeNotifyListeners();
        return;
      }
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }
}
