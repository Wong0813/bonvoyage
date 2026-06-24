import '../models/models.dart';
import 'api_client.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  Future<bool> canReview(int userId, int bookingId) async {
    try {
      final res = await ApiClient.instance.get('/api/reviews/can-review', queryParameters: {
        'userId': userId.toString(),
        'bookingId': bookingId.toString(),
      });
      return res['canReview'] as bool;
    } catch (_) {
      return false;
    }
  }

  Future<void> addReview({
    required int userId,
    required int packageId,
    required int agentId,
    required int bookingId,
    required int rating,
    required String comment,
  }) async {
    await ApiClient.instance.post('/api/reviews', {
      'userId': userId,
      'packageId': packageId,
      'agentId': agentId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<ReviewModel>> getReviews({int? packageId, int? agentId, int? userId}) async {
    final res = await ApiClient.instance.get('/api/reviews', queryParameters: {
      if (packageId != null) 'packageId': packageId.toString(),
      if (agentId != null) 'agentId': agentId.toString(),
      if (userId != null) 'userId': userId.toString(),
    });
    if (res == null) return [];
    return List<ReviewModel>.from((res as List).map((row) {
      final map = Map<String, String?>.from(
        (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
      );
      return ReviewModel(
        id: int.parse(map['id'] ?? '0'),
        userId: int.parse(map['user_id'] ?? '0'),
        packageId: int.parse(map['package_id'] ?? '0'),
        agentId: int.parse(map['agent_id'] ?? '0'),
        bookingId: int.parse(map['booking_id'] ?? '0'),
        rating: int.parse(map['rating'] ?? '5'),
        comment: map['comment'] ?? '',
        status: map['status'] ?? 'active',
        createdAt: parseDate(map['created_at']),
        username: map['username'] ?? '',
        destination: map['destination'] ?? '',
        companyName: map['company_name'] ?? '',
      );
    }));
  }

  Future<void> reportReview(int reviewId, int reporterId, String reason) async {
    await ApiClient.instance.post('/api/reviews/$reviewId/report', {
      'reporterId': reporterId,
      'reason': reason,
    });
  }

  Future<void> moderateReview(int reviewId, String status) async {
    await ApiClient.instance.put('/api/reviews/$reviewId/moderate', {'status': status});
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final res = await ApiClient.instance.get('/api/reviews/reports');
    if (res == null) return [];
    return List<Map<String, dynamic>>.from((res as List).map((row) => Map<String, dynamic>.from(row as Map)));
  }

  Future<double> getAverageRating(int packageId) async {
    final res = await ApiClient.instance.get('/api/reviews/avg/$packageId');
    if (res == null) return 0.0;
    return (res['avgRating'] as num).toDouble();
  }
}
