import '../models/models.dart';
import 'api_client.dart';

class TravelPackageService {
  TravelPackageService._();
  static final TravelPackageService instance = TravelPackageService._();

  Future<List<TravelPackageModel>> getPackages({PackageFilter? filter}) async {
    final res = await ApiClient.instance.get('/api/packages', queryParameters: {
      if (filter?.agentId != null) 'agentId': filter!.agentId.toString(),
      if (filter?.search != null && filter!.search!.isNotEmpty) 'search': filter.search!,
      if (filter?.destination != null && filter!.destination!.isNotEmpty) 'destination': filter.destination!,
      if (filter?.tripType != null && filter!.tripType!.isNotEmpty && filter.tripType != 'all') 'tripType': filter.tripType!,
      if (filter?.minPrice != null) 'minPrice': filter!.minPrice.toString(),
      if (filter?.maxPrice != null) 'maxPrice': filter!.maxPrice.toString(),
      if (filter?.travelDate != null) 'travelDate': dateOnly(filter!.travelDate!),
      if (filter?.category != null && filter!.category!.isNotEmpty) 'category': filter.category!,
    });
    return _parseList(res);
  }

  Future<TravelPackageModel?> getPackageById(int id) async {
    try {
      final res = await ApiClient.instance.get('/api/packages/$id');
      if (res == null) return null;
      return _mapSingle(res);
    } catch (_) {
      return null;
    }
  }

  Future<int> createPackage({
    required int agentProfileId,
    required String destination,
    required String description,
    required String attractions,
    required String tripType,
    required int maxPeople,
    required DateTime travelDate,
    required double pricePerPerson,
    double? promoPrice,
    DateTime? promoEnd,
    String? scheduleFilePath,
    List<Map<String, String>> images = const [],
    required String category,
  }) async {
    final res = await ApiClient.instance.post('/api/packages', {
      'agentProfileId': agentProfileId,
      'destination': destination,
      'description': description,
      'attractions': attractions,
      'tripType': tripType,
      'maxPeople': maxPeople,
      'travelDate': dateOnly(travelDate),
      'pricePerPerson': pricePerPerson,
      if (promoPrice != null) 'promoPrice': promoPrice,
      if (promoEnd != null) 'promoEnd': dateOnly(promoEnd),
      if (scheduleFilePath != null) 'scheduleFilePath': scheduleFilePath,
      'images': images,
      'category': category,
    });
    return res['id'] as int;
  }

  Future<void> updatePackage({
    required int id,
    required int agentProfileId,
    String? destination,
    String? description,
    String? attractions,
    String? tripType,
    int? maxPeople,
    DateTime? travelDate,
    double? pricePerPerson,
    double? promoPrice,
    DateTime? promoEnd,
    String? scheduleFilePath,
    String? status,
    String? category,
  }) async {
    await ApiClient.instance.put('/api/packages/$id', {
      'agentProfileId': agentProfileId,
      if (destination != null) 'destination': destination,
      if (description != null) 'description': description,
      if (attractions != null) 'attractions': attractions,
      if (tripType != null) 'tripType': tripType,
      if (maxPeople != null) 'maxPeople': maxPeople,
      if (travelDate != null) 'travelDate': dateOnly(travelDate),
      if (pricePerPerson != null) 'pricePerPerson': pricePerPerson,
      'promoPrice': promoPrice,
      'promoEnd': promoEnd != null ? dateOnly(promoEnd) : null,
      if (scheduleFilePath != null) 'scheduleFilePath': scheduleFilePath,
      if (status != null) 'status': status,
      if (category != null) 'category': category,
    });
  }

  Future<void> addPackageImages(int packageId, List<Map<String, String>> images) async {
    await ApiClient.instance.post('/api/packages/$packageId/images', {'images': images});
  }

  Future<void> deletePackage(int id, int agentProfileId) async {
    await ApiClient.instance.delete('/api/packages/$id', body: {'agentProfileId': agentProfileId});
  }

  Future<void> deletePackageImage(int id) async {
    await ApiClient.instance.delete('/api/packages/images/$id');
  }

  Future<List<TravelPackageModel>> getAllPackagesAdmin() async {
    final res = await ApiClient.instance.get('/api/packages', queryParameters: {'allAdmin': 'true'});
    return _parseList(res);
  }

  Future<void> adminDeletePackage(int id) async {
    await ApiClient.instance.delete('/api/packages/$id', body: {'adminOverride': true});
  }

  Future<void> adminUpdatePackage({
    required int id,
    String? destination,
    String? description,
    String? attractions,
    String? tripType,
    int? maxPeople,
    DateTime? travelDate,
    double? pricePerPerson,
    double? promoPrice,
    DateTime? promoEnd,
    String? status,
    int? agentProfileId,
    String? category,
  }) async {
    await ApiClient.instance.put('/api/packages/$id', {
      'adminOverride': true,
      if (destination != null) 'destination': destination,
      if (description != null) 'description': description,
      if (attractions != null) 'attractions': attractions,
      if (tripType != null) 'tripType': tripType,
      if (maxPeople != null) 'maxPeople': maxPeople,
      if (travelDate != null) 'travelDate': dateOnly(travelDate),
      if (pricePerPerson != null) 'pricePerPerson': pricePerPerson,
      'promoPrice': promoPrice,
      'promoEnd': promoEnd != null ? dateOnly(promoEnd) : null,
      if (status != null) 'status': status,
      if (agentProfileId != null) 'agentProfileId': agentProfileId,
      if (category != null) 'category': category,
    });
  }

  List<TravelPackageModel> _parseList(dynamic res) {
    if (res == null) return [];
    return List<TravelPackageModel>.from((res as List).map((row) => _mapSingle(row)));
  }

  TravelPackageModel _mapSingle(dynamic row) {
    final map = Map<String, String?>.from(
      (row as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
    );
    final List<PackageImageModel> images = [];
    if (row['images'] != null) {
      for (final img in row['images']) {
        final imgMap = Map<String, String?>.from(
          (img as Map).map((key, val) => MapEntry(key.toString(), val?.toString())),
        );
        images.add(PackageImageModel(
          id: int.parse(imgMap['id'] ?? '0'),
          packageId: int.parse(imgMap['package_id'] ?? '0'),
          imagePath: imgMap['image_path'] ?? '',
          imageType: imgMap['image_type'] ?? 'other',
        ));
      }
    }
    return TravelPackageModel(
      id: int.parse(map['id'] ?? '0'),
      agentId: int.parse(map['agent_id'] ?? '0'),
      destination: map['destination'] ?? '',
      description: map['description'] ?? '',
      attractions: map['attractions'] ?? '',
      tripType: map['trip_type'] ?? 'group',
      maxPeople: int.parse(map['max_people'] ?? '10'),
      travelDate: parseDate(map['travel_date']),
      pricePerPerson: double.tryParse(map['price_per_person'] ?? '0') ?? 0,
      promoPrice: map['promo_price'] != null ? double.tryParse(map['promo_price']!) : null,
      promoEnd: map['promo_end'] != null ? parseDate(map['promo_end']) : null,
      scheduleFilePath: map['schedule_file_path'],
      status: map['status'] ?? 'active',
      companyName: map['company_name'] ?? '',
      agentCode: map['agent_code'] ?? '',
      companyRating: double.tryParse(map['company_rating'] ?? '0') ?? 0,
      chatResponseRate: int.tryParse(map['chat_response_rate'] ?? '100') ?? 100,
      images: images,
      category: map['category'] ?? 'Beach',
    );
  }
}
