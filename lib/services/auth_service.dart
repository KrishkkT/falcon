import 'dart:convert';
import 'dart:async'; // Added for TimeoutException
import 'dart:io'; // Added for SocketException
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'session_manager.dart';
import 'network_config_service.dart'; // Added network config service

class AuthService extends ChangeNotifier {
  static String _baseUrl =
      NetworkConfigService.getBaseApiUrl(); // Use network config service
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'falcon_chat',
    ),
  );

  // Method to update base URL for real devices
  static void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    debugPrint('Auth service base URL updated to: $_baseUrl');
  }

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _authToken;
  SessionManager? _sessionManager;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get authToken => _authToken;

  /// Set session manager instance
  void setSessionManager(SessionManager sessionManager) {
    _sessionManager = sessionManager;
  }

  /// Initialize auth service and check for existing session
  Future<void> initialize() async {
    try {
      _authToken = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'current_user');

      if (_authToken != null && userJson != null) {
        _currentUser = jsonDecode(userJson);
        _isAuthenticated = true;
        debugPrint('Auth service initialized with existing session');
        notifyListeners();
      } else {
        debugPrint('No existing session found');
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    try {
      debugPrint('Starting registration for mobile: $mobile');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$_baseUrl/register');
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Connection', 'keep-alive');

      final body = jsonEncode({
        'name': name,
        'mobile': mobile,
        'password': password,
      });

      request.write(body);

      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('Registration response status: ${response.statusCode}');
      final data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        debugPrint('Registration successful for $mobile');
        client.close();
        return {
          'success': true,
          'message': data['message'],
          'userId': data['userId'],
          'totpSecret': data['totpSecret'],
          'qrCode': data['qrCode'],
        };
      } else {
        debugPrint('Registration failed: ${data['error']}');
        client.close();
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } on TimeoutException catch (e) {
      debugPrint('Registration timeout error: $e');
      return {
        'success': false,
        'message':
            'Request timeout - please check your network connection and try again',
      };
    } on SocketException catch (e) {
      debugPrint('Socket error during registration: $e');
      if (e.message.contains('handshake') || e.message.contains('version')) {
        return {
          'success': false,
          'message':
              'SSL/TLS connection error. Please check server configuration.',
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Login user with mobile, password, and TOTP code
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
    required String totpCode,
  }) async {
    try {
      debugPrint('Starting login for mobile: $mobile');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$_baseUrl/login');
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Connection', 'keep-alive');

      final body = jsonEncode({
        'mobile': mobile,
        'password': password,
        'totpCode': totpCode,
      });

      request.write(body);

      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('Login response status: ${response.statusCode}');
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        debugPrint('Login successful for $mobile');
        _authToken = data['token'];
        _currentUser = data['user'];
        _isAuthenticated = true;

        // Initialize defense-level session
        if (_sessionManager != null) {
          await _sessionManager!.initializeSession(
            _currentUser!['id'].toString(),
            _authToken!,
          );
        }

        // Store credentials securely
        await _storage.write(key: 'auth_token', value: _authToken);
        await _storage.write(
            key: 'current_user', value: jsonEncode(_currentUser));

        notifyListeners();
        client.close();

        return {
          'success': true,
          'message': data['message'],
          'user': _currentUser,
        };
      } else {
        debugPrint('Login failed: ${data['error']}');
        client.close();
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed',
        };
      }
    } on TimeoutException catch (e) {
      debugPrint('Login timeout error: $e');
      return {
        'success': false,
        'message':
            'Request timeout - please check your network connection and try again',
      };
    } on SocketException catch (e) {
      debugPrint('Login network error: $e');
      // Provide a more user-friendly message for network issues
      if (e.message.contains('handshake') || e.message.contains('version')) {
        return {
          'success': false,
          'message':
              'SSL/TLS connection error. Please check server configuration.',
        };
      } else if (e.message.contains('No route to host')) {
        return {
          'success': false,
          'message':
              'Cannot connect to server. Please check your network configuration and ensure the server IP is correct.',
        };
      } else {
        return {
          'success': false,
          'message':
              'Network connection failed. Please check your internet connection.',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Terminate session first
      if (_sessionManager != null) {
        await _sessionManager!.terminateSession('USER_LOGOUT');
      }

      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;

      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'current_user');

      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Check if user is logged in with graceful error handling
  Future<bool> isLoggedIn() async {
    try {
      // First check if we already have the token in memory
      if (_authToken != null && _currentUser != null) {
        return true;
      }

      // Check if we have a token and user data in secure storage
      final token = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'current_user');

      if (token != null && userJson != null) {
        // Load the token and user data into memory
        _authToken = token;
        _currentUser = jsonDecode(userJson);
        _isAuthenticated = true;

        // Validate session with backend, but don't fail immediately on network issues
        try {
          final isValid = await validateBackendSessionWithUserFeedback();
          return isValid;
        } catch (e) {
          debugPrint(
              'Session validation failed, but user data exists in storage: $e');
          // If we can't validate due to network issues, assume session is still valid
          // This prevents unnecessary logouts when offline
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  /// Validate session with backend server and auto-refresh if needed with user-friendly messages
  Future<bool> validateBackendSessionWithUserFeedback() async {
    // If we don't have an auth token, we can't validate
    if (_authToken == null) {
      return false;
    }

    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$_baseUrl/validate-session');
      final request = await client.getUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('Session validation response status: ${response.statusCode}');
      debugPrint('Session validation response body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['valid'] == true) {
          _isAuthenticated = true;
          client.close();
          return true;
        } else {
          // Session is explicitly invalid - show user-friendly message
          debugPrint(
              'Session explicitly invalidated by server: ${data['error']}');
          // Show a user-friendly message that session has expired
          // This would typically be handled by the UI layer
          return await _attemptTokenRefreshWithBackoff(client);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Unauthorized or Forbidden - token is invalid
        debugPrint(
            'Session validation failed: ${response.statusCode} ${response.reasonPhrase}');
        // Show user-friendly message about session expiry
        return await _attemptTokenRefreshWithBackoff(client);
      } else {
        // Other status codes - assume session is still valid if we can't reach server
        debugPrint(
            'Session validation network issue, assuming session valid. Status: ${response.statusCode}');
        client.close();
        return true;
      }
    } on SocketException catch (e) {
      debugPrint('Session validation network error: $e');
      if (e.message.contains('handshake') || e.message.contains('version')) {
        // For SSL/TLS errors, we should be more careful
        debugPrint(
            'SSL/TLS error during session validation, assuming session valid');
        client?.close();
        return true;
      }
      // For other network errors, assume session is still valid
      client?.close();
      return true;
    } on TimeoutException catch (e) {
      debugPrint('Session validation timeout: $e');
      // For timeouts, assume session is still valid
      client?.close();
      return true;
    } catch (e) {
      debugPrint('Session validation error: $e');
      // For other errors, assume session is still valid
      client?.close();
      return true;
    }
  }

  /// Attempt to refresh the authentication token with exponential backoff
  Future<bool> _attemptTokenRefreshWithBackoff(HttpClient client,
      {int retryCount = 0}) async {
    try {
      debugPrint(
          'Attempting to refresh authentication token (attempt ${retryCount + 1})');

      // Close the previous client
      client.close();

      // Try to refresh the token
      final newToken = await refreshToken();

      if (newToken != null) {
        debugPrint('Token refresh successful');
        return true;
      } else {
        // Session invalid, clear stored data
        await _storage.delete(key: 'auth_token');
        await _storage.delete(key: 'current_user');
        _authToken = null;
        _currentUser = null;
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');

      // Retry with exponential backoff for network errors
      if (retryCount < 3) {
        final delay = Duration(seconds: 2 * (retryCount + 1));
        debugPrint(
            'Token refresh failed, retrying in ${delay.inSeconds} seconds');
        await Future.delayed(delay);
        final newClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 15)
          ..idleTimeout = const Duration(seconds: 10);
        return await _attemptTokenRefreshWithBackoff(newClient,
            retryCount: retryCount + 1);
      }

      // Session invalid, clear stored data
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'current_user');
      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Actual token refresh implementation with exponential backoff
  Future<String?> refreshToken({int retryCount = 0}) async {
    try {
      if (_authToken == null) return null;

      debugPrint(
          'Attempting to refresh authentication token (attempt ${retryCount + 1})');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      // Simulate refresh endpoint call
      final uri = Uri.parse('$_baseUrl/refresh-token');
      final request = await client.postUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);

        if (data['token'] != null) {
          _authToken = data['token'];
          _isAuthenticated = true;

          // Store new token securely
          await _storage.write(key: 'auth_token', value: _authToken);

          notifyListeners();
          client.close();
          debugPrint('Token refresh successful');
          return _authToken;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token is invalid, clear stored data and force logout
        debugPrint('Token refresh failed with auth error, logging out');
        await _storage.delete(key: 'auth_token');
        await _storage.delete(key: 'current_user');
        _authToken = null;
        _currentUser = null;
        _isAuthenticated = false;
        notifyListeners();
        client.close();
        return null;
      }

      client.close();

      // Retry with exponential backoff for network errors
      if (retryCount < 3) {
        final delay = Duration(seconds: 2 * (retryCount + 1));
        debugPrint(
            'Token refresh failed, retrying in ${delay.inSeconds} seconds');
        await Future.delayed(delay);
        return await refreshToken(retryCount: retryCount + 1);
      }

      return null;
    } on SocketException catch (e) {
      debugPrint('Token refresh network error: $e');

      // Retry with exponential backoff for network errors
      if (retryCount < 3) {
        final delay = Duration(seconds: 2 * (retryCount + 1));
        debugPrint(
            'Token refresh network error, retrying in ${delay.inSeconds} seconds');
        await Future.delayed(delay);
        return await refreshToken(retryCount: retryCount + 1);
      }

      return null;
    } on TimeoutException catch (e) {
      debugPrint('Token refresh timeout error: $e');

      // Retry with exponential backoff for timeout errors
      if (retryCount < 3) {
        final delay = Duration(seconds: 2 * (retryCount + 1));
        debugPrint(
            'Token refresh timeout, retrying in ${delay.inSeconds} seconds');
        await Future.delayed(delay);
        return await refreshToken(retryCount: retryCount + 1);
      }

      return null;
    } catch (e) {
      debugPrint('Token refresh error: $e');

      // Retry with exponential backoff for other errors
      if (retryCount < 3) {
        final delay = Duration(seconds: 2 * (retryCount + 1));
        debugPrint(
            'Token refresh error, retrying in ${delay.inSeconds} seconds');
        await Future.delayed(delay);
        return await refreshToken(retryCount: retryCount + 1);
      }

      return null;
    }
  }

  /// Auto-refresh token before expiry with exponential backoff
  Future<bool> autoRefreshToken() async {
    try {
      // In a real implementation, we would decode the JWT to check expiry
      // For now, we'll simulate a token that expires in 1 hour
      final token = await refreshToken();
      return token != null;
    } catch (e) {
      debugPrint('Auto-refresh token error: $e');
      return false;
    }
  }

  /// Search for users with exponential backoff retry mechanism
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

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 10);

      final uri = Uri.parse(
          '$_baseUrl/users/search?query=${Uri.encodeComponent(query.trim())}');
      final request = await client.getUrl(uri);

      request.headers.set('Authorization', 'Bearer $_authToken');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Connection', 'keep-alive');

      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        client.close();
        // Ensure we return a proper list even if data is null
        List<Map<String, dynamic>> users;
        if (data is Map<String, dynamic> && data.containsKey('users')) {
          users = List<Map<String, dynamic>>.from(data['users'] ?? []);
        } else {
          users = List<Map<String, dynamic>>.from(data ?? []);
        }
        return users;
      } else if (response.statusCode == 401) {
        client.close();
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 400) {
        final data = jsonDecode(responseBody);
        client.close();
        throw Exception(data['error'] ?? 'Invalid search query');
      } else if (response.statusCode == 404) {
        // User not found - return empty list instead of error for better UX
        client.close();
        return [];
      } else if (response.statusCode == 500) {
        client.close();
        // Retry mechanism for server errors
        if (retryCount < 2) {
          debugPrint(
              'Retrying user search due to server error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await searchUsers(query, retryCount: retryCount + 1);
        }
        throw Exception('Server error. Please try again later.');
      } else {
        // For any other status code, return empty list to avoid breaking UX
        debugPrint('Search failed with status: ${response.statusCode}');
        client.close();
        // Retry mechanism for other errors
        if (retryCount < 1) {
          debugPrint(
              'Retrying user search due to unknown error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await searchUsers(query, retryCount: retryCount + 1);
        }
        return [];
      }
    } on TimeoutException {
      debugPrint('Search timeout error');
      // Retry mechanism for timeout errors
      if (retryCount < 2) {
        debugPrint(
            'Retrying user search due to timeout (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await searchUsers(query, retryCount: retryCount + 1);
      }
      throw Exception(
          'Search timed out. Please check your network connection and try again.');
    } on SocketException catch (e) {
      debugPrint('Network error during search: $e');
      if (e.message.contains('handshake') || e.message.contains('version')) {
        throw Exception(
            'SSL/TLS connection error. Please check server configuration.');
      }
      // Retry mechanism for network errors
      if (retryCount < 2) {
        debugPrint(
            'Retrying user search due to network error (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await searchUsers(query, retryCount: retryCount + 1);
      }
      throw Exception(
          'Network error. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('Search error: $e');
      // Provide user-friendly error messages
      if (e.toString().contains('Network')) {
        // Retry mechanism for network errors
        if (retryCount < 2) {
          debugPrint(
              'Retrying user search due to network error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await searchUsers(query, retryCount: retryCount + 1);
        }
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('timeout')) {
        // Retry mechanism for timeout errors
        if (retryCount < 2) {
          debugPrint(
              'Retrying user search due to timeout (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await searchUsers(query, retryCount: retryCount + 1);
        }
        throw Exception(
            'Search timed out. Please check your network connection and try again.');
      } else {
        // Retry mechanism for other errors
        if (retryCount < 1) {
          debugPrint(
              'Retrying user search due to unknown error (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return await searchUsers(query, retryCount: retryCount + 1);
        }
        // For "user not found" or similar cases, return empty list instead of error
        return [];
      }
    }
  }

  /// Get authorization headers for API calls
  Map<String, String> getAuthHeaders() {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }

    // Validate session before API call
    if (_sessionManager != null && !_sessionManager!.isSessionActive) {
      throw Exception('Session expired');
    }

    // Update activity on API usage
    _sessionManager?.updateActivity();

    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
      'user-id': _currentUser?['id']?.toString() ?? '1',
    };
  }

  /// Validate current session
  Future<bool> validateSession() async {
    if (_sessionManager == null) return true; // Fallback if no session manager
    return await _sessionManager!.validateSession();
  }

  /// Force session renewal for high-security operations
  Future<bool> renewSession() async {
    if (_sessionManager == null) return true;
    return await _sessionManager!.renewSession();
  }

  /// Logout user with proper cleanup and user feedback
  Future<void> logoutWithFeedback() async {
    try {
      // Terminate session first
      if (_sessionManager != null) {
        await _sessionManager!.terminateSession('USER_LOGOUT');
      }

      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;

      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'current_user');

      notifyListeners();

      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
      // Even if there's an error, clear local state
      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Handle expired token with user-friendly message
  Future<void> handleExpiredToken() async {
    // Clear local session data
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'current_user');
    _authToken = null;
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();

    debugPrint('Session expired, user needs to login again');
    // The UI layer would handle showing the "Session expired, login again" message
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
