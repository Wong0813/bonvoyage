class ReviewModel {
  final int id;
  final int userId;
  final int packageId;
  final int agentId;
  final int bookingId;
  final int rating;
  final String comment;
  final String status;
  final DateTime createdAt;
  final String username;
  final String destination;
  final String companyName;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.agentId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
    this.username = '',
    this.destination = '',
    this.companyName = '',
  });
}
