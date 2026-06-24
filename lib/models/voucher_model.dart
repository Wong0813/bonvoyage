class VoucherModel {
  final int id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minPurchase;
  final int maxUses;
  final int usedCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String status;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minPurchase,
    required this.maxUses,
    required this.usedCount,
    this.validFrom,
    this.validUntil,
    required this.status,
  });

  bool get isValid {
    if (status != 'active') return false;
    if (usedCount >= maxUses) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  double calculateDiscount(double subtotal) {
    if (!isValid || subtotal < minPurchase) return 0;
    if (discountType == 'percent') {
      return subtotal * discountValue / 100;
    }
    return discountValue;
  }
}
