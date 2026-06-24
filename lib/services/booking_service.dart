import '../models/models.dart';
import 'api_client.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  Future<int> createBooking({
    required int userId,
    required int packageId,
    required int agentId,
    required String guestName,
    required String icPassport,
    required int numPeople,
    required DateTime travelDate,
    required double unitPrice,
    String? specialRequirements,
    String? voucherCode,
  }) async {
    final res = await ApiClient.instance.post('/api/bookings', {
      'userId': userId,
      'packageId': packageId,
      'agentId': agentId,
      'guestName': guestName,
      'icPassport': icPassport,
      'numPeople': numPeople,
      'travelDate': dateOnly(travelDate),
      'unitPrice': unitPrice,
      if (specialRequirements != null) 'specialRequirements': specialRequirements,
      if (voucherCode != null) 'voucherCode': voucherCode,
    });
    return res['id'] as int;
  }

  Future<void> confirmPayment(int bookingId, int userId) async {
    await ApiClient.instance.post('/api/bookings/$bookingId/pay', {'userId': userId});
  }

  Future<void> updateBookingStatus(int bookingId, String status, {int? agentId}) async {
    await ApiClient.instance.put('/api/bookings/$bookingId/status', {
      'status': status,
      if (agentId != null) 'agentId': agentId,
    });
  }

  Future<void> markCompleted(int bookingId) async {
    await updateBookingStatus(bookingId, 'completed');
  }

  Future<List<BookingModel>> getBookingsByUser(int userId) async {
    final res = await ApiClient.instance.get('/api/bookings', queryParameters: {'userId': userId.toString()});
    return _parseBookings(res);
  }

  Future<List<BookingModel>> getBookingsByAgent(int agentProfileId) async {
    final res = await ApiClient.instance.get('/api/bookings', queryParameters: {'agentId': agentProfileId.toString()});
    return _parseBookings(res);
  }

  Future<List<BookingModel>> getAllBookings() async {
    final res = await ApiClient.instance.get('/api/bookings');
    return _parseBookings(res);
  }

  Future<BookingModel?> getBookingById(int id) async {
    try {
      final res = await ApiClient.instance.get('/api/bookings/$id');
      if (res == null) return null;
      return _mapSingle(res);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>> getStats() async {
    final res = await ApiClient.instance.get('/api/bookings/stats');
    if (res == null) return {};
    return Map<String, int>.from((res as Map).map((key, val) => MapEntry(key.toString(), int.parse(val.toString()))));
  }

  List<BookingModel> _parseBookings(dynamic res) {
    if (res == null) return [];
    return List<BookingModel>.from((res as List).map((row) => _mapSingle(row)));
  }

  BookingModel _mapSingle(dynamic row) {
    final map = Map<String, String?>.from(
      (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
    );
    return BookingModel(
      id: int.parse(map['id'] ?? '0'),
      userId: int.parse(map['user_id'] ?? '0'),
      packageId: int.parse(map['package_id'] ?? '0'),
      agentId: int.parse(map['agent_id'] ?? '0'),
      guestName: map['guest_name'] ?? '',
      icPassport: map['ic_passport'] ?? '',
      numPeople: int.parse(map['num_people'] ?? '1'),
      specialRequirements: map['special_requirements'],
      voucherCode: map['voucher_code'],
      discountAmount: double.tryParse(map['discount_amount'] ?? '0') ?? 0,
      totalPrice: double.tryParse(map['total_price'] ?? '0') ?? 0,
      paymentStatus: map['payment_status'] ?? 'pending',
      status: map['status'] ?? 'pending',
      travelDate: parseDate(map['travel_date']),
      createdAt: parseDate(map['created_at']),
      username: map['username'] ?? '',
      destination: map['destination'] ?? '',
      companyName: map['company_name'] ?? '',
      isReviewed: (int.tryParse(map['review_count'] ?? '0') ?? 0) > 0,
    );
  }
}
