import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

class ErrorReportingService {
  static final ErrorReportingService _instance =
      ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  bool _initialized = false;

  /// Initialize error reporting service
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        // Don't initialize Sentry in debug mode
        _initialized = false;
        debugPrint(
            'Error reporting service: Skipping Sentry initialization in debug mode');
        return;
      }

      // Initialize Sentry with your DSN
      await SentryFlutter.init(
        (options) {
          options.dsn =
              'YOUR_SENTRY_DSN_HERE'; // Replace with your actual Sentry DSN
          // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring
          options.tracesSampleRate = 1.0;
          // Enable automatic error reporting
          options.enableAutoSessionTracking = true;

          // Enable debug mode when needed
          options.debug = false;
        },
        appRunner: () {
          // This won't be called in our case since we're initializing Sentry manually
        },
      );

      _initialized = true;
      debugPrint('Error reporting service initialized with Sentry');
    } catch (e) {
      _initialized = false;
      debugPrint('Error reporting service initialization failed: $e');
    }
  }

  /// Report an error to Sentry
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extraData,
  }) async {
    if (!_initialized) return;

    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (context != null) {
            scope.setContexts('context', {'description': context});
          }
          if (extraData != null) {
            scope.setContexts('extra_data', extraData);
          }
        },
      );
      debugPrint('Error reported to Sentry: $error');
    } catch (e) {
      debugPrint('Failed to report error to Sentry: $e');
    }
  }

  /// Report a message to Sentry
  Future<void> reportMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extraData,
  }) async {
    if (!_initialized) return;

    try {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: (scope) {
          if (extraData != null) {
            scope.setContexts('extra_data', extraData);
          }
        },
      );
      debugPrint('Message reported to Sentry: $message');
    } catch (e) {
      debugPrint('Failed to report message to Sentry: $e');
    }
  }

  /// Add breadcrumb for debugging
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) async {
    if (!_initialized) return;

    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: level,
          data: data,
        ),
      );
    } catch (e) {
      debugPrint('Failed to add breadcrumb to Sentry: $e');
    }
  }

  /// Close Sentry client
  Future<void> close() async {
    if (!_initialized) return;

    try {
      await Sentry.close();
      _initialized = false;
      debugPrint('Error reporting service closed');
    } catch (e) {
      debugPrint('Failed to close error reporting service: $e');
    }
  }

  /// Check if error reporting is initialized
  bool get isInitialized => _initialized;

  /// Set user context for error reporting
  Future<void> setUserContext({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return;

    try {
      await Sentry.configureScope((scope) {
        scope.setUser(
          SentryUser(
            id: id,
            email: email,
            username: username,
            extras: extras,
          ),
        );
      });
    } catch (e) {
      debugPrint('Failed to set user context in Sentry: $e');
    }
  }

  /// Clear user context
  Future<void> clearUserContext() async {
    if (!_initialized) return;

    try {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    } catch (e) {
      debugPrint('Failed to clear user context in Sentry: $e');
    }
  }
}
