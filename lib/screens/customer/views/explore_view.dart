import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/app_theme.dart';

class ExploreView extends StatelessWidget {
  final UserModel user;
  final List<TravelPackageModel> packages;
  final List<BookingModel> bookings;
  final Function(TravelPackageModel) onOpenPackage;
  final Function(TravelPackageModel) onBookPackage;
  final TextEditingController searchCtrl;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  ExploreView({
    super.key,
    required this.user,
    required this.packages,
    required this.bookings,
    required this.onOpenPackage,
    required this.onBookPackage,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final List<Map<String, dynamic>> _destinations = [
    {
      'name': 'Santorini',
      'country': 'Greece',
      'price': '\$1,299',
      'rating': '4.9',
      'duration': '7 days',
      'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      'emoji': '🏛️',
      'desc': 'White-washed villages perched on volcanic cliffs above the Aegean Sea.',
      'attractions': 'Oia Sunset, Fira Caldera, Red Beach',
      'imageUrl': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=800&q=80',
    },
    {
      'name': 'Bali',
      'country': 'Indonesia',
      'price': '\$899',
      'rating': '4.8',
      'duration': '5 days',
      'gradient': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      'emoji': '🌴',
      'desc': 'Tropical paradise of lush rice terraces, ancient temples, and sandy beaches.',
      'attractions': 'Ubud Monkey Forest, Tanah Lot Temple, Uluwatu Cliff',
      'imageUrl': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=800&q=80',
    },
    {
      'name': 'Tokyo',
      'country': 'Japan',
      'price': '\$1,599',
      'rating': '4.9',
      'duration': '10 days',
      'gradient': [const Color(0xFFf953c6), const Color(0xFFb91d73)],
      'emoji': '🗼',
      'desc': 'Neon-lit skyscrapers blending ultramodern technology with traditional temples.',
      'attractions': 'Shibuya Crossing, Senso-ji Temple, Meiji Shrine',
      'imageUrl': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=800&q=80',
    },
    {
      'name': 'Maldives',
      'country': 'Maldives',
      'price': '\$2,199',
      'rating': '5.0',
      'duration': '6 days',
      'gradient': [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
      'emoji': '🏝️',
      'desc': 'Crystal-clear turquoise waters, vibrant coral reefs, and luxury overwater bungalows.',
      'attractions': 'Male Atolls, Banana Reef, private island resorts',
      'imageUrl': 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?auto=format&fit=crop&w=800&q=80',
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Beach', 'emoji': '🏖️', 'color': const Color(0xFF00D4FF)},
    {'label': 'Mountains', 'emoji': '⛰️', 'color': const Color(0xFF4ECDC4)},
    {'label': 'City', 'emoji': '🏙️', 'color': const Color(0xFF6C63FF)},
    {'label': 'Culture', 'emoji': '🏛️', 'color': const Color(0xFFFF6B9D)},
    {'label': 'Adventure', 'emoji': '🧗', 'color': const Color(0xFFF7971E)},
  ];

  @override
  Widget build(BuildContext context) {
    final upcoming = bookings.where((b) => b.status == 'confirmed' || b.status == 'pending').toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 750;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: AppTheme.input('Search destinations...').copyWith(
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
        ],
        _buildHeroBanner(),
        const SizedBox(height: 28),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final label = cat['label'] as String;
              final color = cat['color'] as Color;
              final emoji = cat['emoji'] as String;
              final isSelected = selectedCategory == label;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    if (isSelected) {
                      onCategoryChanged(null);
                    } else {
                      onCategoryChanged(label);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : color.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        const Text('Popular Destinations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        isMobile ? _buildDestinationsHorizontal() : _buildDestinationsGrid(),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Travel Packages', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            if (searchCtrl.text.isNotEmpty || selectedCategory != null)
              TextButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.close_rounded, color: Color(0xFF00D4FF), size: 14),
                label: Text(
                  searchCtrl.text.isNotEmpty && selectedCategory != null
                      ? 'Clear filters'
                      : searchCtrl.text.isNotEmpty
                          ? 'Clear filter: "${searchCtrl.text}"'
                          : 'Clear category: "$selectedCategory"',
                  style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        packages.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No packages found', style: TextStyle(color: Colors.white54))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packages.length,
                itemBuilder: (context, idx) {
                  final pkg = packages[idx];
                  return _packageCard(context, pkg);
                },
              ),
        const SizedBox(height: 28),
        const Text('My Upcoming Trips', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        upcoming.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: const Center(
                  child: Text('No upcoming trips. Book a package above!', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              )
            : Column(children: upcoming.map((t) => _buildTripCard(t)).toList()),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4), Color(0xFF45B7D1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Text('✈️', style: TextStyle(fontSize: 100, color: Colors.white.withValues(alpha: 0.15))),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ready for your next\nadventure? ✨',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsHorizontal() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _destinations.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(right: i < _destinations.length - 1 ? 14 : 0),
          child: _destinationCard(context, _destinations[i]),
        ),
      ),
    );
  }

  Widget _buildDestinationsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _destinations.length,
      itemBuilder: (context, i) => _destinationCard(context, _destinations[i]),
    );
  }

  Widget _destinationCard(BuildContext context, Map<String, dynamic> dest) {
    final hasImg = dest.containsKey('imageUrl') && dest['imageUrl'] != null && (dest['imageUrl'] as String).isNotEmpty;
    return InkWell(
      onTap: () {
        searchCtrl.text = dest['name'] as String;
        onSearchChanged(dest['name'] as String);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: hasImg ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dest['gradient'] as List<Color>,
          ),
          boxShadow: [
            BoxShadow(
              color: (dest['gradient'] as List<Color>)[0].withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (hasImg)
                Positioned.fill(
                  child: Image.network(
                    dest['imageUrl'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: dest['gradient'] as List<Color>,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Text(dest['emoji'] as String, style: const TextStyle(fontSize: 40)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(dest['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(dest['country'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dest['price'] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text(dest['rating'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('⏱ ${dest['duration']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _packageCard(BuildContext context, TravelPackageModel pkg) {
    final hasPromo = pkg.hasPromotion;
    final priceStr = 'RM ${pkg.pricePerPerson.toStringAsFixed(2)}';
    final promoStr = hasPromo ? 'RM ${pkg.promoPrice!.toStringAsFixed(2)}' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: () => onOpenPackage(pkg),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppTheme.buildPackageImage(pkg.images),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pkg.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(pkg.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(pkg.tripType.toUpperCase(), style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(pkg.category).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_getCategoryEmoji(pkg.category)} ${pkg.category.toUpperCase()}',
                            style: TextStyle(color: _getCategoryColor(pkg.category), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(pkg.companyName, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (promoStr != null) ...[
                    Text(priceStr, style: const TextStyle(color: Colors.white38, fontSize: 11, decoration: TextDecoration.lineThrough)),
                    Text(promoStr, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ] else
                    Text(priceStr, style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('per person', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(BookingModel trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: () {
          final actualPkg = packages.any((p) => p.id == trip.packageId)
              ? packages.firstWhere((p) => p.id == trip.packageId)
              : TravelPackageModel(
                  id: trip.packageId,
                  agentId: trip.agentId,
                  destination: trip.destination,
                  description: '',
                  attractions: '',
                  tripType: 'group',
                  maxPeople: trip.numPeople,
                  travelDate: trip.travelDate,
                  pricePerPerson: trip.totalPrice,
                  status: trip.status,
                  companyName: trip.companyName,
                  agentCode: '',
                  companyRating: 5.0,
                  chatResponseRate: 100,
                  images: [],
                  category: 'Beach',
                );
          onOpenPackage(actualPkg);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppTheme.buildPackageImage(
                packages.any((p) => p.id == trip.packageId)
                    ? packages.firstWhere((p) => p.id == trip.packageId).images
                    : const [],
                size: 48,
                radius: 12,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(trip.travelDate.toIso8601String().split('T').first, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Booking ID: #${trip.id} · ${trip.guestName}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trip.status == 'confirmed'
                      ? Colors.green.withValues(alpha: 0.15)
                      : trip.status == 'completed'
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: trip.status == 'confirmed'
                        ? Colors.green.withValues(alpha: 0.3)
                        : trip.status == 'completed'
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  trip.status.toUpperCase(),
                  style: TextStyle(
                    color: trip.status == 'confirmed'
                        ? Colors.greenAccent
                        : trip.status == 'completed'
                            ? Colors.lightBlueAccent
                            : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'beach': return const Color(0xFF00D4FF);
      case 'mountains': return const Color(0xFF4ECDC4);
      case 'city': return const Color(0xFF6C63FF);
      case 'culture': return const Color(0xFFFF6B9D);
      case 'adventure': return const Color(0xFFF7971E);
      default: return const Color(0xFF4ECDC4);
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'beach': return '🏖️';
      case 'mountains': return '⛰️';
      case 'city': return '🏙️';
      case 'culture': return '🏛️';
      case 'adventure': return '🧗';
      default: return '📍';
    }
  }
}
