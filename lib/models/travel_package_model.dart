class PackageImageModel {
  final int id;
  final int packageId;
  final String imagePath;
  final String imageType;

  const PackageImageModel({
    required this.id,
    required this.packageId,
    required this.imagePath,
    required this.imageType,
  });
}

class TravelPackageModel {
  final int id;
  final int agentId;
  final String destination;
  final String description;
  final String attractions;
  final String tripType;
  final int maxPeople;
  final DateTime travelDate;
  final double pricePerPerson;
  final double? promoPrice;
  final DateTime? promoEnd;
  final String? scheduleFilePath;
  final String status;
  final String companyName;
  final String agentCode;
  final double companyRating;
  final int chatResponseRate;
  final List<PackageImageModel> images;
  final String category;

  const TravelPackageModel({
    required this.id,
    required this.agentId,
    required this.destination,
    required this.description,
    required this.attractions,
    required this.tripType,
    required this.maxPeople,
    required this.travelDate,
    required this.pricePerPerson,
    this.promoPrice,
    this.promoEnd,
    this.scheduleFilePath,
    required this.status,
    this.companyName = '',
    this.agentCode = '',
    this.companyRating = 0,
    this.chatResponseRate = 100,
    this.images = const [],
    required this.category,
  });

  double get effectivePrice =>
      promoPrice != null && (promoEnd == null || !DateTime.now().isAfter(promoEnd!))
          ? promoPrice!
          : pricePerPerson;

  bool get hasPromotion =>
      promoPrice != null && (promoEnd == null || !DateTime.now().isAfter(promoEnd!));

  List<String> get attractionsList => attractions
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

class PackageFilter {
  final String? search;
  final double? minPrice;
  final double? maxPrice;
  final String? destination;
  final String? tripType;
  final DateTime? travelDate;
  final int? agentId;
  final String? category;

  const PackageFilter({
    this.search,
    this.minPrice,
    this.maxPrice,
    this.destination,
    this.tripType,
    this.travelDate,
    this.agentId,
    this.category,
  });
}
