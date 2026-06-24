import '../models/models.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> create({
    int? userId,
    int? agentId,
    String targetRole = 'user',
    required String title,
    required String message,
  }) async {
    await ApiClient.instance.post('/api/notifications', {
      if (userId != null) 'userId': userId,
      if (agentId != null) 'agentId': agentId,
      'targetRole': targetRole,
      'title': title,
      'message': message,
    });
  }

  Future<void> broadcast({
    required String targetRole,
    required String title,
    required String message,
  }) async {
    await ApiClient.instance.post('/api/notifications/broadcast', {
      'targetRole': targetRole,
      'title': title,
      'message': message,
    });
  }

  Future<List<NotificationModel>> getForUser(int userId) async {
    final res = await ApiClient.instance.get('/api/notifications', queryParameters: {'userId': userId.toString()});
    return _parseList(res);
  }

  Future<List<NotificationModel>> getForAgent(int agentProfileId) async {
    final res = await ApiClient.instance.get('/api/notifications', queryParameters: {'agentId': agentProfileId.toString()});
    return _parseList(res);
  }

  Future<void> markRead(int id) async {
    await ApiClient.instance.put('/api/notifications/$id/read', {});
  }

  Future<void> markAllRead({int? userId, int? agentId}) async {
    await ApiClient.instance.put('/api/notifications/read-all', {
      if (userId != null) 'userId': userId,
      if (agentId != null) 'agentId': agentId,
    });
  }

  Future<int> unreadCountForUser(int userId) async {
    final res = await ApiClient.instance.get('/api/notifications/unread-count', queryParameters: {'userId': userId.toString()});
    if (res == null) return 0;
    return res['count'] as int;
  }

  List<NotificationModel> _parseList(dynamic res) {
    if (res == null) return [];
    return List<NotificationModel>.from((res as List).map((row) {
      final map = Map<String, String?>.from(
        (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
      );
      return NotificationModel(
        id: int.parse(map['id'] ?? '0'),
        userId: map['user_id'] != null ? int.tryParse(map['user_id']!) : null,
        agentId: map['agent_id'] != null ? int.tryParse(map['agent_id']!) : null,
        targetRole: map['target_role'] ?? 'user',
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        isRead: map['is_read'] == '1',
        createdAt: parseDate(map['created_at']),
      );
    }));
  }
}
