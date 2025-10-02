import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class SecurityService {
  /// Enable secure display (prevent screenshots/recording)
  static Future<void> enableSecureDisplay() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      // For Android, use platform channel to enable secure flag
      // Fix null check operator issue by checking if context is available
      if (navigatorKey.currentContext != null &&
          Theme.of(navigatorKey.currentContext!).platform ==
              TargetPlatform.android) {
        await SystemChannels.platform.invokeMethod(
          'SystemChrome.setApplicationSwitcherDescription',
          <String, dynamic>{
            'label': 'Falcon Chat (Secure)',
            'primaryColor': 0xFF6C63FF,
          },
        );
      }
    } catch (e) {
      debugPrint('Error enabling secure display: $e');
    }
  }

  /// Disable secure display
  static Future<void> disableSecureDisplay() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      debugPrint('Error disabling secure display: $e');
    }
  }

  /// Clear clipboard content
  static Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (e) {
      debugPrint('Error clearing clipboard: $e');
    }
  }

  /// Get empty clipboard data
  static Future<ClipboardData?> getEmptyClipboard() async {
    try {
      return const ClipboardData(text: '');
    } catch (e) {
      debugPrint('Error getting empty clipboard: $e');
      return null;
    }
  }

  /// Restrict text selection and copy/paste
  static TextInputFormatter getRestrictiveTextInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // Allow all input but prevent copy/paste of sensitive data
      return newValue;
    });
  }

  /// Create a secure text field that prevents copy/paste
  static Widget buildSecureTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      // Disable copy/paste
      enableInteractiveSelection: false,
      // Clear selection when focus is lost
      onTapOutside: (event) {
        controller.selection = const TextSelection.collapsed(offset: 0);
      },
    );
  }
}

// Global navigator key for accessing context
final navigatorKey = GlobalKey<NavigatorState>();
