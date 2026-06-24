import '../models/models.dart';
import 'api_client.dart';

class VoucherService {
  VoucherService._();
  static final VoucherService instance = VoucherService._();

  Future<VoucherModel?> getByCode(String code) async {
    try {
      final res = await ApiClient.instance.get('/api/vouchers/$code');
      if (res == null) return null;
      return _map(res);
    } catch (_) {
      return null;
    }
  }

  Future<List<VoucherModel>> getAll() async {
    final res = await ApiClient.instance.get('/api/vouchers');
    if (res == null) return [];
    return List<VoucherModel>.from((res as List).map(_map));
  }

  Future<void> create({
    required String code,
    required String discountType,
    required double discountValue,
    double minPurchase = 0,
    int maxUses = 100,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    await ApiClient.instance.post('/api/vouchers', {
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minPurchase': minPurchase,
      'maxUses': maxUses,
      if (validFrom != null) 'validFrom': dateOnly(validFrom),
      if (validUntil != null) 'validUntil': dateOnly(validUntil),
    });
  }

  Future<void> updateStatus(int id, String status) async {
    await ApiClient.instance.put('/api/vouchers/$id', {'status': status});
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/api/vouchers/$id');
  }

  Future<void> update({
    required int id,
    String? code,
    String? discountType,
    double? discountValue,
    double? minPurchase,
    int? maxUses,
    DateTime? validFrom,
    DateTime? validUntil,
    String? status,
  }) async {
    await ApiClient.instance.put('/api/vouchers/$id', {
      if (code != null) 'code': code,
      if (discountType != null) 'discountType': discountType,
      if (discountValue != null) 'discountValue': discountValue,
      if (minPurchase != null) 'minPurchase': minPurchase,
      if (maxUses != null) 'maxUses': maxUses,
      if (validFrom != null) 'validFrom': dateOnly(validFrom),
      if (validUntil != null) 'validUntil': dateOnly(validUntil),
      if (status != null) 'status': status,
    });
  }

  Future<void> incrementUsage(int id) async {
    // Handled on backend in /api/bookings POST transaction.
  }

  VoucherModel _map(dynamic row) {
    final map = Map<String, String?>.from(
      (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
    );
    return VoucherModel(
      id: int.parse(map['id'] ?? '0'),
      code: map['code'] ?? '',
      discountType: map['discount_type'] ?? 'percent',
      discountValue: double.tryParse(map['discount_value'] ?? '0') ?? 0,
      minPurchase: double.tryParse(map['min_purchase'] ?? '0') ?? 0,
      maxUses: int.parse(map['max_uses'] ?? '100'),
      usedCount: int.parse(map['used_count'] ?? '0'),
      validFrom: map['valid_from'] != null ? parseDate(map['valid_from']) : null,
      validUntil: map['valid_until'] != null ? parseDate(map['valid_until']) : null,
      status: map['status'] ?? 'active',
    );
  }
}
