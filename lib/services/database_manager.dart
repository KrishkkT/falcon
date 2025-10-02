import 'dart:async';
// import 'dart:io'; // Removed unused import
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseManager {
  static Database? _database;
  static const String _databaseName = 'falcon_chat.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _usersTable = 'users';
  static const String _messagesTable = 'messages';
  static const String _conversationsTable = 'conversations';
  static const String _contactsTable = 'contacts';

  /// Get database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with encryption
  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    // Use a strong encryption key - in production, this should be derived from user credentials
    // or stored securely using flutter_secure_storage
    final encryptionKey = 'falcon_secure_messaging_app_2025';

    return await openDatabase(
      path,
      password: encryptionKey,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Users table for local user cache
      await txn.execute('''
        CREATE TABLE $_usersTable (
          id TEXT PRIMARY KEY,
          mobile TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          public_key TEXT,
          profile_picture TEXT,
          last_seen INTEGER,
          is_online INTEGER DEFAULT 0,
          created_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Messages table for local message cache
      await txn.execute('''
        CREATE TABLE $_messagesTable (
          id TEXT PRIMARY KEY,
          conversation_id TEXT NOT NULL,
          sender_id TEXT NOT NULL,
          recipient_id TEXT NOT NULL,
          message_text TEXT NOT NULL,
          encrypted_content TEXT,
          message_type TEXT DEFAULT 'text',
          timestamp INTEGER NOT NULL,
          delivery_status TEXT DEFAULT 'sent',
          is_read INTEGER DEFAULT 0,
          reply_to_message_id TEXT,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (sender_id) REFERENCES $_usersTable (id),
          FOREIGN KEY (recipient_id) REFERENCES $_usersTable (id)
        )
      ''');

      // Conversations table for chat list
      await txn.execute('''
        CREATE TABLE $_conversationsTable (
          id TEXT PRIMARY KEY,
          participant1_id TEXT NOT NULL,
          participant2_id TEXT NOT NULL,
          last_message_id TEXT,
          last_message_text TEXT,
          last_message_timestamp INTEGER,
          unread_count INTEGER DEFAULT 0,
          is_archived INTEGER DEFAULT 0,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (participant1_id) REFERENCES $_usersTable (id),
          FOREIGN KEY (participant2_id) REFERENCES $_usersTable (id),
          FOREIGN KEY (last_message_id) REFERENCES $_messagesTable (id)
        )
      ''');

      // Contacts table for user's contact list
      await txn.execute('''
        CREATE TABLE $_contactsTable (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          contact_user_id TEXT NOT NULL,
          display_name TEXT,
          is_favorite INTEGER DEFAULT 0,
          is_blocked INTEGER DEFAULT 0,
          added_at INTEGER DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (user_id) REFERENCES $_usersTable (id),
          FOREIGN KEY (contact_user_id) REFERENCES $_usersTable (id),
          UNIQUE(user_id, contact_user_id)
        )
      ''');

      // Create indexes for better performance
      await txn.execute(
          'CREATE INDEX idx_messages_conversation ON $_messagesTable (conversation_id, timestamp DESC)');
      await txn.execute(
          'CREATE INDEX idx_messages_sender ON $_messagesTable (sender_id)');
      await txn.execute(
          'CREATE INDEX idx_messages_recipient ON $_messagesTable (recipient_id)');
      await txn.execute(
          'CREATE INDEX idx_conversations_participants ON $_conversationsTable (participant1_id, participant2_id)');
      await txn.execute(
          'CREATE INDEX idx_contacts_user ON $_contactsTable (user_id)');
    });
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  /// Insert or update user
  static Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      _usersTable,
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user by ID
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final users = await db.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return users.isNotEmpty ? users.first : null;
  }

  /// Search users by name or mobile
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final db = await database;
    return await db.query(
      _usersTable,
      where: 'name LIKE ? OR mobile LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: 20,
    );
  }

  /// Insert message
  static Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      _messagesTable,
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update conversation
    await _updateConversation(
      message['conversation_id'],
      message['id'],
      message['message_text'],
      message['timestamp'],
    );
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.query(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get messages between two users
  static Future<List<Map<String, dynamic>>> getMessagesBetweenUsers(
    String user1Id,
    String user2Id, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.query(
      _messagesTable,
      where:
          '(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)',
      whereArgs: [user1Id, user2Id, user2Id, user1Id],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Update message delivery status
  static Future<void> updateMessageStatus(
      String messageId, String status) async {
    final db = await database;
    await db.update(
      _messagesTable,
      {'delivery_status': status},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Mark message as read
  static Future<void> markMessageAsRead(String messageId) async {
    final db = await database;
    await db.update(
      _messagesTable,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Get or create conversation between two users
  static Future<String> getOrCreateConversation(
      String user1Id, String user2Id) async {
    final db = await database;

    // Try to find existing conversation
    final conversations = await db.query(
      _conversationsTable,
      where:
          '(participant1_id = ? AND participant2_id = ?) OR (participant1_id = ? AND participant2_id = ?)',
      whereArgs: [user1Id, user2Id, user2Id, user1Id],
      limit: 1,
    );

    if (conversations.isNotEmpty) {
      return conversations.first['id'] as String;
    }

    // Create new conversation
    final conversationId =
        '${user1Id}_${user2Id}_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(_conversationsTable, {
      'id': conversationId,
      'participant1_id': user1Id,
      'participant2_id': user2Id,
    });

    return conversationId;
  }

  /// Get conversation list
  static Future<List<Map<String, dynamic>>> getConversations(
      String userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, u.name as other_user_name, u.mobile as other_user_mobile
      FROM $_conversationsTable c
      JOIN $_usersTable u ON (
        CASE 
          WHEN c.participant1_id = ? THEN u.id = c.participant2_id
          ELSE u.id = c.participant1_id
        END
      )
      WHERE c.participant1_id = ? OR c.participant2_id = ?
      ORDER BY c.last_message_timestamp DESC
    ''', [userId, userId, userId]);
  }

  /// Update conversation with last message info
  static Future<void> _updateConversation(
    String conversationId,
    String messageId,
    String messageText,
    int timestamp,
  ) async {
    final db = await database;
    await db.update(
      _conversationsTable,
      {
        'last_message_id': messageId,
        'last_message_text': messageText,
        'last_message_timestamp': timestamp,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Add contact
  static Future<void> addContact(String userId, String contactUserId,
      {String? displayName}) async {
    final db = await database;
    await db.insert(
      _contactsTable,
      {
        'id': '${userId}_$contactUserId',
        'user_id': userId,
        'contact_user_id': contactUserId,
        'display_name': displayName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get contacts for user
  static Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, u.name, u.mobile, u.last_seen, u.is_online
      FROM $_contactsTable c
      JOIN $_usersTable u ON c.contact_user_id = u.id
      WHERE c.user_id = ? AND c.is_blocked = 0
      ORDER BY u.name ASC
    ''', [userId]);
  }

  /// Clear all data (for logout)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_messagesTable);
      await txn.delete(_conversationsTable);
      await txn.delete(_contactsTable);
      await txn.delete(_usersTable);
    });
  }

  /// Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final usersCount =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_usersTable');
    final messagesCount =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_messagesTable');
    final conversationsCount =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_conversationsTable');
    final contactsCount =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_contactsTable');

    return {
      'users': usersCount.first['count'] as int,
      'messages': messagesCount.first['count'] as int,
      'conversations': conversationsCount.first['count'] as int,
      'contacts': contactsCount.first['count'] as int,
    };
  }

  /// Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
