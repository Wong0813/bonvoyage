import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<UserModel?> login(String username, String password) async {
    try {
      final res = await ApiClient.instance.post('/api/auth/login', {
        'username': username,
        'password': password,
      });
      if (res == null) return null;
      return UserModel.fromRow(Map<String, String?>.from(res));
    } catch (e) {
      if (e.toString().contains('suspended')) {
        throw Exception('Account suspended. Contact administrator.');
      }
      return null;
    }
  }

  Future<bool> registerCustomer({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    try {
      await ApiClient.instance.post('/api/auth/register-customer', {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerAgent({
    required String username,
    required String password,
    required String email,
    required String companyName,
    required String phone,
    required String location,
  }) async {
    try {
      await ApiClient.instance.post('/api/auth/register-agent', {
        'username': username,
        'password': password,
        'email': email,
        'companyName': companyName,
        'phone': phone,
        'location': location,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile({
    required int userId,
    String? username,
    String? password,
    String? fullName,
    String? icPassport,
    String? phone,
    String? email,
  }) async {
    try {
      await ApiClient.instance.post('/api/auth/update-profile', {
        'userId': userId,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
        if (fullName != null) 'fullName': fullName,
        if (icPassport != null) 'icPassport': icPassport,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(String username, String email, String newPassword) async {
    try {
      await ApiClient.instance.post('/api/auth/reset-password', {
        'username': username,
        'email': email,
        'newPassword': newPassword,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getUserById(int id) async {
    try {
      final res = await ApiClient.instance.get('/api/auth/user/$id');
      if (res == null) return null;
      return UserModel.fromRow(Map<String, String?>.from(res));
    } catch (_) {
      return null;
    }
  }
}
