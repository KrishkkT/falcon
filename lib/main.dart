import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart'; // Add Sentry import

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_screen.dart'; // Add debug screen import
import 'services/auth_service.dart';
import 'services/vpn_service.dart';
import 'services/chat_service.dart';
import 'services/session_manager.dart';
import 'services/network_config_service.dart';
import 'services/security_service.dart';
import 'services/screenshot_protection_service.dart';
import 'services/config_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/error_reporting_service.dart'; // Add error reporting service
import 'services/log_service.dart'; // Add log service import
import 'widgets/session_status_widget.dart';
import 'widgets/screenshot_overlay.dart';
import 'widgets/connection_status_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add global error handling to prevent crashes
  FlutterError.onError = (details) {
    // Log the error but don't crash the app
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable secure display for the entire app
  try {
    await SecurityService.enableSecureDisplay();
  } catch (e) {
    debugPrint('Failed to enable secure display: $e');
    // Continue even if secure display fails
  }

  runApp(const FalconApp());
}

class FalconApp extends StatelessWidget {
  const FalconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionManager()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => VpnService()),
        ChangeNotifierProvider(create: (_) => ScreenshotProtectionService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LogService()), // Add log service
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          // Initialize services
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final notificationService =
                Provider.of<NotificationService>(context, listen: false);
            notificationService.initialize();

            // Initialize push notification service
            _initializePushNotificationService(context);

            // Initialize error reporting service
            _initializeErrorReportingService(context);

            // Initialize log service
            await _initializeLogService(context);
          });

          return MaterialApp(
            title: 'Falcon - Secure Chat',
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: false,
            showSemanticsDebugger: false,
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: ConnectionStatusIndicator(
                  child: ScreenshotOverlay(
                    child: NoDebugWidget(child: child!),
                  ),
                ),
              );
            },
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegistrationScreen(),
              '/chat': (context) => const ChatScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/contacts': (context) => const ContactsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/debug': (context) => const DebugScreen(), // Add debug screen
            },
          );
        },
      ),
    );
  }

  /// Initialize push notification service
  Future<void> _initializePushNotificationService(BuildContext context) async {
    try {
      final pushNotificationService = PushNotificationService();
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);

      await pushNotificationService.initialize(
        onMessageReceived: (messageData) {
          debugPrint('Push notification received: $messageData');
          // Handle incoming message
        },
        onNotificationTap: (conversationId) {
          debugPrint(
              'Push notification tapped for conversation: $conversationId');
          // Navigate to chat screen
          if (Navigator.canPop(context)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  recipientId: conversationId.split('_').first,
                  recipientName: 'Unknown User',
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing push notification service: $e');
    }
  }

  /// Initialize error reporting service
  Future<void> _initializeErrorReportingService(BuildContext context) async {
    try {
      final errorReportingService = ErrorReportingService();
      await errorReportingService.initialize();

      // Set up global error handling
      FlutterError.onError = (details) {
        if (!kDebugMode) {
          errorReportingService.reportError(
            details.exception,
            details.stack ??
                StackTrace.current, // Provide a fallback stack trace
            context: 'Flutter Error',
            extraData: {
              'library': details.library,
              'context': details.context?.toString(),
            },
          );
        }
      };

      // Set up async error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          errorReportingService.reportError(
            error,
            stack,
            context: 'Platform Error',
          );
        }
        return true;
      };
    } catch (e) {
      debugPrint('Error initializing error reporting service: $e');
    }
  }

  /// Initialize log service
  Future<void> _initializeLogService(BuildContext context) async {
    try {
      final logService = Provider.of<LogService>(context, listen: false);
      await logService.initialize();

      // Set up global logging
      if (kDebugMode) {
        logService.info('App', 'Falcon Secure Chat app started');
      }
    } catch (e) {
      debugPrint('Error initializing log service: $e');
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      try {
        // Initialize network configuration
        await _initializeNetworkConfig();

        // Initialize screenshot protection
        final screenshotService = Provider.of<ScreenshotProtectionService>(
          context,
          listen: false,
        );
        await screenshotService.initialize();

        final authService = Provider.of<AuthService>(context, listen: false);
        final vpnService = Provider.of<VpnService>(context, listen: false);

        // Try to start VPN automatically - but handle errors gracefully
        try {
          await _startVpnIfNeeded(vpnService);
        } catch (e) {
          debugPrint('VPN auto-start failed (this is OK): $e');
          // Don't let VPN errors prevent app startup
        }

        if (await _checkAuthentication(authService)) {
          // Validate existing session
          if (await authService.validateSession()) {
            debugPrint('Valid session found, navigating to dashboard');
            if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            // Session expired, go to login
            debugPrint('Session expired, logging out');
            await authService.logout();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          debugPrint('No session found, navigating to login');
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        debugPrint('Error during splash screen initialization: $e');
        // If there's any error, go to login screen as fallback
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  Future<void> _startVpnIfNeeded(VpnService vpnService) async {
    try {
      // Check if VPN is already connected
      if (vpnService.isConnected) {
        debugPrint('VPN already connected');
        // Inform chat service about VPN status
        final chatService = Provider.of<ChatService>(context, listen: false);
        chatService.setVpnStatus(true);
        return;
      }

      // For local development, don't auto-start VPN
      if (kDebugMode) {
        debugPrint('Development mode: Not auto-starting VPN');
        // Inform chat service about VPN status
        final chatService = Provider.of<ChatService>(context, listen: false);
        chatService.setVpnStatus(false);
        return;
      }

      // Check if VPN permission is granted
      final isPermissionGranted = await vpnService.isVpnPermissionGranted();
      if (!isPermissionGranted) {
        debugPrint('VPN permission not granted, skipping auto-connect');
        // Inform chat service about VPN status
        final chatService = Provider.of<ChatService>(context, listen: false);
        chatService.setVpnStatus(false);
        return;
      }

      // Try to start VPN
      debugPrint('Attempting to start VPN automatically');
      await vpnService.startVpn();
      debugPrint('VPN started successfully');

      // Inform chat service about VPN status
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.setVpnStatus(true);
    } catch (e) {
      debugPrint('Failed to start VPN automatically: $e');
      // Inform chat service about VPN status
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.setVpnStatus(false);
      // Don't throw the error, just log it - we don't want VPN issues to prevent app usage
    }
  }

  Future<void> _initializeNetworkConfig() async {
    try {
      // Initialize configuration service
      await ConfigService.initialize();

      // For your current setup: Local development
      if (kDebugMode) {
        // For development/testing, use local network
        NetworkConfigService.updateForLocalNetwork('172.20.10.2', 3001);
        NetworkConfigService.setProductionMode(false);
        NetworkConfigService.setForceVpnLocal(
            ConfigService.forceVpnLocal); // Use config service
        NetworkConfigService.setVpnStatus(false); // Start with VPN off
        debugPrint(
            '🔧 Development mode: Using local server 172.20.10.2:3001 with VPN local mode: ${ConfigService.forceVpnLocal}');
      } else {
        // For production, use local server as well (removing AWS references)
        NetworkConfigService.updateForLocalNetwork('172.20.10.2', 3001);
        NetworkConfigService.setProductionMode(false);
        NetworkConfigService.setForceVpnLocal(
            ConfigService.forceVpnLocal); // Use config service
        NetworkConfigService.setVpnStatus(false); // Start with VPN off
        debugPrint(
            '🚀 Production mode: Using local server 172.20.10.2:3001 with VPN local mode: ${ConfigService.forceVpnLocal}');
      }

      // Update the network configuration
      debugPrint('Initializing network configuration');

      // Update the network configuration to use the correct URLs
      final baseUrl = NetworkConfigService.getBaseApiUrl();
      final wsUrl = NetworkConfigService.getWebSocketUrl();

      // Update service URLs
      ChatService.updateBaseUrls(baseUrl, wsUrl);
      AuthService.updateBaseUrl(baseUrl);

      // Also update the network config service with the current VPN status
      final vpnService = Provider.of<VpnService>(context, listen: false);
      NetworkConfigService.setVpnStatus(vpnService.isConnected);
    } catch (e) {
      debugPrint('Error initializing network config: $e');
    }
  }

  Future<bool> _checkAuthentication(AuthService authService) async {
    try {
      return await authService.isLoggedIn();
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App Name
                      const Text(
                        'Falcon',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Secure • Private • Protected',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.8),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
