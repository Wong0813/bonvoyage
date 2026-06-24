import '../models/models.dart';
import 'api_client.dart';

class AgentProfileService {
  AgentProfileService._();
  static final AgentProfileService instance = AgentProfileService._();

  Future<AgentProfileModel?> getByUserId(int userId) async {
    try {
      final res = await ApiClient.instance.get('/api/agents/user/$userId');
      if (res == null) return null;
      return AgentProfileModel.fromRow(Map<String, String?>.from(res));
    } catch (_) {
      return null;
    }
  }

  Future<AgentProfileModel?> getById(int id) async {
    try {
      final res = await ApiClient.instance.get('/api/agents/$id');
      if (res == null) return null;
      return AgentProfileModel.fromRow(Map<String, String?>.from(res));
    } catch (_) {
      return null;
    }
  }

  Future<List<AgentProfileModel>> getAll() async {
    final res = await ApiClient.instance.get('/api/agents');
    if (res == null) return [];
    return List<AgentProfileModel>.from(
      (res as List).map((row) => AgentProfileModel.fromRow(Map<String, String?>.from(row))),
    );
  }

  Future<void> updateProfile({
    required int agentProfileId,
    String? companyName,
    String? phone,
    String? location,
    String? logoPath,
    String? socialFacebook,
    String? socialInstagram,
    String? socialWebsite,
  }) async {
    await ApiClient.instance.put('/api/agents/$agentProfileId', {
      if (companyName != null) 'companyName': companyName,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (logoPath != null) 'logoPath': logoPath,
      if (socialFacebook != null) 'socialFacebook': socialFacebook,
      if (socialInstagram != null) 'socialInstagram': socialInstagram,
      if (socialWebsite != null) 'socialWebsite': socialWebsite,
    });
  }
}
