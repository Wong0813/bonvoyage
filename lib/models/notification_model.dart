class NotificationModel {
  final int id;
  final int? userId;
  final int? agentId;
  final String targetRole;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    this.agentId,
    required this.targetRole,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });
}
