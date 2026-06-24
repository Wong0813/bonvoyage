import '../models/models.dart';
import 'api_client.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Future<List<UserModel>> getAllUsers({String? role}) async {
    final Map<String, String>? params = role != null ? {'role': role} : null;
    final res = await ApiClient.instance.get('/api/admin/users', queryParameters: params);
    if (res == null) return [];
    return List<UserModel>.from((res as List).map((r) => UserModel.fromRow(Map<String, String?>.from(r))));
  }

  Future<void> updateUserStatus(int userId, String status) async {
    await ApiClient.instance.put('/api/admin/users/$userId/status', {'status': status});
  }

  Future<void> deleteUser(int userId) async {
    await ApiClient.instance.delete('/api/admin/users/$userId');
  }

  Future<void> updateUserPassword(int userId, String newPassword) async {
    await ApiClient.instance.put('/api/admin/users/$userId/password', {'password': newPassword});
  }

  Future<void> resetUserPassword(int userId, String newPassword) async {
    await updateUserPassword(userId, newPassword);
  }

  Future<bool> createUser({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required String role,
    String? phone,
    String? icPassport,
    String? companyName,
    String? location,
  }) async {
    try {
      await ApiClient.instance.post('/api/admin/users', {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
        'role': role,
        'phone': phone,
        'icPassport': icPassport,
        'companyName': companyName,
        'location': location,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateUser({
    required int userId,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    String? icPassport,
  }) async {
    await ApiClient.instance.post('/api/auth/update-profile', {
      'userId': userId,
      if (username != null && username.isNotEmpty) 'username': username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (icPassport != null) 'icPassport': icPassport,
    });
  }

  Future<Map<String, String>> getSettings() async {
    final res = await ApiClient.instance.get('/api/settings');
    if (res == null) return {};
    return Map<String, String>.from(res as Map);
  }

  Future<void> updateSetting(String key, String value) async {
    await ApiClient.instance.post('/api/settings', {'key': key, 'value': value});
  }

  Future<Map<String, int>> getDashboardStats() async {
    final res = await ApiClient.instance.get('/api/admin/stats');
    if (res == null) return {};
    return Map<String, int>.from(res as Map);
  }
}
