import '../models/models.dart';
import 'api_client.dart';

class ItineraryService {
  ItineraryService._();
  static final ItineraryService instance = ItineraryService._();

  Future<List<ItineraryItemModel>> getByBooking(int bookingId) async {
    final res = await ApiClient.instance.get('/api/itineraries', queryParameters: {'bookingId': bookingId.toString()});
    if (res == null) return [];
    return List<ItineraryItemModel>.from((res as List).map((r) {
      final m = Map<String, String?>.from((r as Map).map((key, val) => MapEntry(key.toString(), val?.toString())));
      return ItineraryItemModel(
        id: int.parse(m['id'] ?? '0'),
        bookingId: int.parse(m['booking_id'] ?? '0'),
        dayNumber: int.parse(m['day_number'] ?? '1'),
        timeSlot: m['time_slot'] ?? 'morning',
        activity: m['activity'] ?? '',
        location: m['location'] ?? '',
        notes: m['notes'],
      );
    }));
  }

  Future<int> addItem({
    required int bookingId,
    required int dayNumber,
    required String timeSlot,
    required String activity,
    required String location,
    String? notes,
  }) async {
    final res = await ApiClient.instance.post('/api/itineraries', {
      'bookingId': bookingId,
      'dayNumber': dayNumber,
      'timeSlot': timeSlot,
      'activity': activity,
      'location': location,
      if (notes != null) 'notes': notes,
    });
    return res['id'] as int;
  }

  Future<void> updateItem(int id, {String? activity, String? location, String? notes, String? timeSlot}) async {
    await ApiClient.instance.put('/api/itineraries/$id', {
      if (activity != null) 'activity': activity,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (timeSlot != null) 'timeSlot': timeSlot,
    });
  }

  Future<void> removeItem(int id) async {
    await ApiClient.instance.delete('/api/itineraries/$id');
  }
}
