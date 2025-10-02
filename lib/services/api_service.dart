import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ApiService {
  // Base URL for API calls - can be configured for remote access
  static String baseUrl =
      'http://172.20.10.2:3000'; // Change to your server IP for remote access

  // Timeout duration for API calls
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Make a POST request to the API
  static Future<http.Response> post(String path, Map body) async {
    final headers = {'Content-Type': 'application/json'};
    try {
      final uri = Uri.parse('$baseUrl$path');
      debugPrint('Making POST request to: $uri');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);

      debugPrint('POST response status: ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('API POST Timeout for $path: $e');
      throw Exception('Request timeout - please check your network connection');
    } catch (e) {
      debugPrint('API POST Error for $path: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Make an authenticated GET request to the API
  static Future<http.Response> getAuth(String path) async {
    final authService = AuthService();
    final token = authService.authToken ?? '';

    if (token.isEmpty) {
      throw Exception('Not authenticated');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    try {
      final uri = Uri.parse('$baseUrl$path');
      debugPrint('Making GET request to: $uri');

      final response =
          await http.get(uri, headers: headers).timeout(timeoutDuration);

      debugPrint('GET response status: ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('API GET Timeout for $path: $e');
      throw Exception('Request timeout - please check your network connection');
    } catch (e) {
      debugPrint('API GET Error for $path: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Update base URL for remote access
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    debugPrint('API base URL updated to: $baseUrl');
  }
}
