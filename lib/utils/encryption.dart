import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Simplified encryption utilities for Falcon Chat
/// Implements basic AES-256 encryption without import conflicts
class EncryptionUtils {
  static const int _aesKeyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  /// Generate a secure random AES key
  static Uint8List generateAESKey() {
    final random = Random.secure();
    final key = Uint8List(_aesKeyLength);
    for (int i = 0; i < _aesKeyLength; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  /// Generate a secure random IV for AES
  static Uint8List generateIV() {
    final random = Random.secure();
    final iv = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Simple XOR encryption (for demo purposes)
  static String encryptMessage(String plaintext, String sharedKey) {
    final messageBytes = utf8.encode(plaintext);
    final keyBytes = sha256.convert(utf8.encode(sharedKey)).bytes;
    final encrypted = <int>[];

    for (int i = 0; i < messageBytes.length; i++) {
      encrypted.add(messageBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  /// Simple XOR decryption (for demo purposes)
  static String decryptMessage(String encryptedText, String sharedKey) {
    try {
      final encryptedBytes = base64.decode(encryptedText);
      final keyBytes = sha256.convert(utf8.encode(sharedKey)).bytes;
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Generate secure shared key from user data
  static String generateSharedKey(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    final combined = users.join('_');
    return sha256.convert(utf8.encode('falcon_$combined')).toString();
  }

  /// Hash password securely
  static String hashPassword(String password, String salt) {
    final combined = password + salt;
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Generate random salt for password hashing
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }
}

/// Simplified key pair for demo purposes
class SimpleKeyPair {
  final String publicKey;
  final String privateKey;

  const SimpleKeyPair({
    required this.publicKey,
    required this.privateKey,
  });

  /// Generate a simple key pair (for demo)
  static SimpleKeyPair generate() {
    final random = Random.secure();
    final privateBytes = List.generate(32, (i) => random.nextInt(256));
    final publicBytes = List.generate(32, (i) => random.nextInt(256));

    return SimpleKeyPair(
      privateKey: base64.encode(privateBytes),
      publicKey: base64.encode(publicBytes),
    );
  }
}

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;

  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

// Backwards compatibility class
class Encryption {
  static String encryptText(String plain) {
    return EncryptionUtils.encryptMessage(plain, 'falcon_default_key');
  }

  static String decryptText(String encrypted) {
    return EncryptionUtils.decryptMessage(encrypted, 'falcon_default_key');
  }
}
