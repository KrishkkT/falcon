import 'dart:convert';

/// Utility class for API response schema validation
class ApiValidator {
  /// Validate conversation response schema
  static bool validateConversationsSchema(dynamic data) {
    try {
      // Check if data is a list or object with conversations array
      if (data is List) {
        return _validateConversationList(data);
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('conversations') &&
            data['conversations'] is List) {
          return _validateConversationList(data['conversations'] as List);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate individual conversation schema
  static bool validateConversationSchema(Map<String, dynamic> conversation) {
    try {
      // Required fields
      if (!conversation.containsKey('id') || conversation['id'] == null) {
        return false;
      }

      if (!conversation.containsKey('name') || conversation['name'] == null) {
        return false;
      }

      // Optional fields with type checking
      if (conversation.containsKey('unreadCount') &&
          conversation['unreadCount'] != null &&
          conversation['unreadCount'] is! int) {
        return false;
      }

      if (conversation.containsKey('isOnline') &&
          conversation['isOnline'] != null &&
          conversation['isOnline'] is! bool) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate message response schema
  static bool validateMessagesSchema(dynamic data) {
    try {
      // Check if data is a list or object with messages array
      if (data is List) {
        return _validateMessageList(data);
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('messages') && data['messages'] is List) {
          return _validateMessageList(data['messages'] as List);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate individual message schema
  static bool validateMessageSchema(Map<String, dynamic> message) {
    try {
      // Required fields
      if (!message.containsKey('id') || message['id'] == null) {
        return false;
      }

      if (!message.containsKey('senderId') || message['senderId'] == null) {
        return false;
      }

      if (!message.containsKey('recipientId') ||
          message['recipientId'] == null) {
        return false;
      }

      if (!message.containsKey('message') && !message.containsKey('mediaUrl')) {
        return false; // Must have either message text or media
      }

      if (!message.containsKey('timestamp') || message['timestamp'] == null) {
        return false;
      }

      // Validate timestamp format
      try {
        DateTime.parse(message['timestamp'].toString());
      } catch (e) {
        return false;
      }

      // Optional fields with type checking
      if (message.containsKey('deliveryStatus') &&
          message['deliveryStatus'] != null &&
          message['deliveryStatus'] is! String) {
        return false;
      }

      if (message.containsKey('read') &&
          message['read'] != null &&
          message['read'] is! bool) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate user response schema
  static bool validateUsersSchema(dynamic data) {
    try {
      // Check if data is a list or object with users array
      if (data is List) {
        return _validateUserList(data);
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('users') && data['users'] is List) {
          return _validateUserList(data['users'] as List);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate individual user schema
  static bool validateUserSchema(Map<String, dynamic> user) {
    try {
      // Required fields
      if (!user.containsKey('id') || user['id'] == null) {
        return false;
      }

      if (!user.containsKey('name') || user['name'] == null) {
        return false;
      }

      if (!user.containsKey('mobile') || user['mobile'] == null) {
        return false;
      }

      // Validate mobile format (basic check)
      final mobile = user['mobile'].toString();
      if (mobile.isEmpty || mobile.length < 10) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Private helper methods
  static bool _validateConversationList(List conversations) {
    if (conversations.isEmpty) return true;

    for (var item in conversations) {
      if (item is! Map<String, dynamic>) return false;
      if (!validateConversationSchema(item)) return false;
    }
    return true;
  }

  static bool _validateMessageList(List messages) {
    if (messages.isEmpty) return true;

    for (var item in messages) {
      if (item is! Map<String, dynamic>) return false;
      if (!validateMessageSchema(item)) return false;
    }
    return true;
  }

  static bool _validateUserList(List users) {
    if (users.isEmpty) return true;

    for (var item in users) {
      if (item is! Map<String, dynamic>) return false;
      if (!validateUserSchema(item)) return false;
    }
    return true;
  }
}
