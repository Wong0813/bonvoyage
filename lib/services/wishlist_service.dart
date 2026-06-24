import 'api_client.dart';

class WishlistService {
  WishlistService._();
  static final WishlistService instance = WishlistService._();

  Future<List<int>> getPackageIdsByUser(int userId) async {
    final res = await ApiClient.instance.get('/api/wishlist/$userId');
    if (res == null) return [];
    return List<int>.from((res as List).map((id) => int.parse(id.toString())));
  }

  Future<bool> isWishlisted(int userId, int packageId) async {
    final res = await ApiClient.instance.get('/api/wishlist/$userId/$packageId');
    if (res == null) return false;
    return res['isWishlisted'] as bool;
  }

  Future<bool> toggle(int userId, int packageId) async {
    final res = await ApiClient.instance.post('/api/wishlist/toggle', {
      'userId': userId,
      'packageId': packageId,
    });
    return res['wishlisted'] as bool;
  }
}
