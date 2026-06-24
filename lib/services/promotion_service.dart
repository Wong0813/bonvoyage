import '../models/models.dart';
import 'api_client.dart';

class PromotionService {
  PromotionService._();
  static final PromotionService instance = PromotionService._();

  Future<List<PromotionModel>> getActive() async {
    final res = await ApiClient.instance.get('/api/promotions', queryParameters: {'activeOnly': 'true'});
    return _parseList(res);
  }

  Future<List<PromotionModel>> getAll() async {
    final res = await ApiClient.instance.get('/api/promotions');
    return _parseList(res);
  }

  Future<void> create({
    required String title,
    required String description,
    double? discountPercent,
    int? packageId,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    await ApiClient.instance.post('/api/promotions', {
      'title': title,
      'description': description,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (packageId != null) 'packageId': packageId,
      if (validFrom != null) 'validFrom': dateOnly(validFrom),
      if (validUntil != null) 'validUntil': dateOnly(validUntil),
    });
  }

  Future<void> updateStatus(int id, String status) async {
    await ApiClient.instance.put('/api/promotions/$id', {'status': status});
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/api/promotions/$id');
  }

  Future<void> update({
    required int id,
    String? title,
    String? description,
    double? discountPercent,
    int? packageId,
    DateTime? validFrom,
    DateTime? validUntil,
    String? status,
  }) async {
    await ApiClient.instance.put('/api/promotions/$id', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (packageId != null) 'packageId': packageId,
      if (validFrom != null) 'validFrom': dateOnly(validFrom),
      if (validUntil != null) 'validUntil': dateOnly(validUntil),
      if (status != null) 'status': status,
    });
  }

  List<PromotionModel> _parseList(dynamic res) {
    if (res == null) return [];
    return List<PromotionModel>.from((res as List).map((row) {
      final map = Map<String, String?>.from(
        (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
      );
      return PromotionModel(
        id: int.parse(map['id'] ?? '0'),
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        discountPercent: map['discount_percent'] != null ? double.tryParse(map['discount_percent']!) : null,
        packageId: map['package_id'] != null ? int.tryParse(map['package_id']!) : null,
        validFrom: map['valid_from'] != null ? parseDate(map['valid_from']) : null,
        validUntil: map['valid_until'] != null ? parseDate(map['valid_until']) : null,
        status: map['status'] ?? 'active',
        packageDestination: map['package_destination'],
      );
    }));
  }
}
