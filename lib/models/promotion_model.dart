class PromotionModel {
  final int id;
  final String title;
  final String description;
  final double? discountPercent;
  final int? packageId;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String status;
  final String? packageDestination;

  const PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    this.discountPercent,
    this.packageId,
    this.validFrom,
    this.validUntil,
    required this.status,
    this.packageDestination,
  });

  bool get isActive {
    if (status != 'active') return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }
}
