class BookingModel {
  final int id;
  final int userId;
  final int packageId;
  final int agentId;
  final String guestName;
  final String icPassport;
  final int numPeople;
  final String? specialRequirements;
  final String? voucherCode;
  final double discountAmount;
  final double totalPrice;
  final String paymentStatus;
  final String status;
  final DateTime travelDate;
  final DateTime createdAt;
  final String username;
  final String destination;
  final String companyName;
  final bool isReviewed;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.agentId,
    required this.guestName,
    required this.icPassport,
    required this.numPeople,
    this.specialRequirements,
    this.voucherCode,
    required this.discountAmount,
    required this.totalPrice,
    required this.paymentStatus,
    required this.status,
    required this.travelDate,
    required this.createdAt,
    this.username = '',
    this.destination = '',
    this.companyName = '',
    this.isReviewed = false,
  });

  bool get isCompleted => status == 'completed';
  bool get isPaid => paymentStatus == 'paid';
  bool get canReview => (status == 'completed' || status == 'confirmed') && !isReviewed;
}
