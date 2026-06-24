class AgentProfileModel {
  final int id;
  final String agentId;
  final int userId;
  final String companyName;
  final String phone;
  final String location;
  final String? logoPath;
  final String? socialFacebook;
  final String? socialInstagram;
  final String? socialWebsite;
  final double rating;
  final int chatResponseRate;
  final String username;
  final String? userStatus;

  const AgentProfileModel({
    required this.id,
    required this.agentId,
    required this.userId,
    required this.companyName,
    required this.phone,
    required this.location,
    this.logoPath,
    this.socialFacebook,
    this.socialInstagram,
    this.socialWebsite,
    required this.rating,
    required this.chatResponseRate,
    this.username = '',
    this.userStatus,
  });

  factory AgentProfileModel.fromRow(Map<String, String?> row) {
    return AgentProfileModel(
      id: int.parse(row['id'] ?? '0'),
      agentId: row['agent_id'] ?? '',
      userId: int.parse(row['user_id'] ?? '0'),
      companyName: row['company_name'] ?? '',
      phone: row['phone'] ?? '',
      location: row['location'] ?? '',
      logoPath: row['logo_path'],
      socialFacebook: row['social_facebook'],
      socialInstagram: row['social_instagram'],
      socialWebsite: row['social_website'],
      rating: double.tryParse(row['rating'] ?? '0') ?? 0,
      chatResponseRate: int.tryParse(row['chat_response_rate'] ?? '100') ?? 100,
      username: row['username'] ?? '',
      userStatus: row['user_status'],
    );
  }
}
