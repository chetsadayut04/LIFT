import 'database_helper.dart';

class AiChatMessageItem {
  final int? id;
  final String uuid;
  final bool isUser;
  final String text;
  final DateTime timestamp;

  AiChatMessageItem({
    this.id,
    required this.uuid,
    required this.isUser,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'is_user': isUser ? 1 : 0,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AiChatMessageItem.fromMap(Map<String, dynamic> map) {
    return AiChatMessageItem(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      isUser: (map['is_user'] as int) == 1,
      text: map['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

class AiChatMessageDao {
  Future<void> insertMessage({
    required String uuid,
    required bool isUser,
    required String text,
    required DateTime timestamp,
  }) async {
    final db = await DatabaseHelper.database;
    await db.insert('ai_chat_messages', {
      'uuid': uuid,
      'is_user': isUser ? 1 : 0,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
    });
  }

  Future<List<AiChatMessageItem>> getMessages({int limit = 100}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'ai_chat_messages',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return maps.map(AiChatMessageItem.fromMap).toList();
  }

  Future<void> clearAll() async {
    final db = await DatabaseHelper.database;
    await db.delete('ai_chat_messages');
  }
}
