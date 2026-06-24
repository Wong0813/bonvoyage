class UserModel {
  final int id;
  final String? memberId;
  final String username;
  final String email;
  final String role;
  final String fullName;
  final String? icPassport;
  final String? phone;
  final String status;

  const UserModel({
    required this.id,
    this.memberId,
    required this.username,
    required this.email,
    required this.role,
    required this.fullName,
    this.icPassport,
    this.phone,
    required this.status,
  });

  bool get isAdmin => role == 'admin';
  bool get isAgent => role == 'agent';
  bool get isCustomer => role == 'user';
  bool get isSuspended => status == 'suspended';

  factory UserModel.fromRow(Map<String, String?> row) {
    return UserModel(
      id: int.parse(row['id'] ?? '0'),
      memberId: row['member_id'],
      username: row['username'] ?? '',
      email: row['email'] ?? '',
      role: row['role'] ?? 'user',
      fullName: row['full_name'] ?? '',
      icPassport: row['ic_passport'],
      phone: row['phone'],
      status: row['status'] ?? 'active',
    );
  }
}
