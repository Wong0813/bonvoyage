import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/app_theme.dart';

class PackagesView extends StatelessWidget {
  final List<TravelPackageModel> packages;
  final List<BookingModel> bookings;
  final List<ReviewModel> reviews;
  final AgentProfileModel profile;
  final VoidCallback onAddPackage;
  final Function(TravelPackageModel) onEditPackage;
  final Function(TravelPackageModel) onDeletePackage;

  const PackagesView({
    super.key,
    required this.packages,
    required this.bookings,
    required this.reviews,
    required this.profile,
    required this.onAddPackage,
    required this.onEditPackage,
    required this.onDeletePackage,
  });

  @override
  Widget build(BuildContext context) {
    final int pendingBookings = bookings.where((b) => b.status == 'pending').length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildStatsGrid(context, pendingBookings),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Travel Packages (${packages.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton.icon(
              onPressed: onAddPackage,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Package', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (packages.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.luggage_rounded, color: Colors.white.withValues(alpha: 0.2), size: 48),
                  const SizedBox(height: 12),
                  Text('No travel packages uploaded yet.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                ],
              ),
            ),
          )
        else
          _buildPackagesGrid(context),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int pendingBookings) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 950;
    final double contentWidth = isDesktop ? (width - 260) : width;

    int crossCount = 2;
    if (contentWidth >= 800) crossCount = 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: crossCount == 4 ? 1.4 : 1.6,
      children: [
        _statCard('Total Packages', '${packages.length}', Icons.luggage_rounded, [const Color(0xFF00c6ff), const Color(0xFF0072ff)]),
        _statCard('Total Reservations', '${bookings.length}', Icons.book_online_rounded, [const Color(0xFF667eea), const Color(0xFF764ba2)]),
        _statCard('Client Reviews', '${reviews.length}', Icons.star_rounded, [const Color(0xFF11998e), const Color(0xFF38ef7d)]),
        _statCard('Pending Requests', '$pendingBookings', Icons.hourglass_empty_rounded, [const Color(0xFFf857a6), const Color(0xFFff5858)]),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: colors[1].withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -15, bottom: -15, child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.12))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    Icon(icon, color: Colors.white, size: 16),
                  ],
                ),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPackagesGrid(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 950;
    final double contentWidth = isDesktop ? (width - 260) : width;

    int crossCount = 1;
    if (contentWidth >= 600 && contentWidth < 900) crossCount = 2;
    if (contentWidth >= 900) crossCount = 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, idx) {
        final p = packages[idx];
        final hasImage = p.images.isNotEmpty;
        final double price = p.effectivePrice;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      hasImage
                          ? AppTheme.imageFromPath(
                              p.images.first.imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                color: const Color(0xFF0F0E26),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00D4FF),
                                  ),
                                ),
                              ),
                              errorWidget: Container(
                                color: const Color(0xFF0F0E26),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF0F0E26),
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                              ),
                            ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.tripType.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: PopupMenuButton(
                          icon: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black45,
                            child: Icon(Icons.more_vert, color: Colors.white, size: 16),
                          ),
                          color: const Color(0xFF16162A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                          onSelected: (v) {
                            if (v == 'edit') onEditPackage(p);
                            if (v == 'delete') onDeletePackage(p);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit Package', style: TextStyle(color: Colors.white, fontSize: 13))),
                            const PopupMenuItem(value: 'delete', child: Text('Delete Package', style: TextStyle(color: Colors.redAccent, fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PRICE', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text('RM ${price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  '${p.travelDate.year}-${p.travelDate.month.toString().padLeft(2, "0")}-${p.travelDate.day.toString().padLeft(2, "0")}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
