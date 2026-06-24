class ChatMessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String senderName;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderName = '',
  });
}
