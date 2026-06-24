import '../models/models.dart';
import 'api_client.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Future<void> sendMessage({
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    await ApiClient.instance.post('/api/chats/message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
    });
  }

  Future<List<ChatMessageModel>> getConversation(int userId1, int userId2) async {
    final res = await ApiClient.instance.get('/api/chats/conversation', queryParameters: {
      'user1': userId1.toString(),
      'user2': userId2.toString(),
    });
    if (res == null) return [];
    return List<ChatMessageModel>.from((res as List).map((row) {
      final map = Map<String, String?>.from(
        (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
      );
      return ChatMessageModel(
        id: int.parse(map['id'] ?? '0'),
        senderId: int.parse(map['sender_id'] ?? '0'),
        receiverId: int.parse(map['receiver_id'] ?? '0'),
        message: map['message'] ?? '',
        isRead: map['is_read'] == '1',
        createdAt: parseDate(map['created_at']),
        senderName: map['sender_name'] ?? '',
      );
    }));
  }

  Future<List<Map<String, dynamic>>> getContactsForUser(int userId) async {
    final res = await ApiClient.instance.get('/api/chats/contacts/$userId');
    if (res == null) return [];
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<AgentProfileModel>> getAllAgentsForChat() async {
    final res = await ApiClient.instance.get('/api/agents');
    if (res == null) return [];
    return List<AgentProfileModel>.from((res as List)
        .map((row) => AgentProfileModel.fromRow(Map<String, String?>.from(row)))
        .where((a) => a.userStatus == 'active' || a.userStatus == null));
  }
}
