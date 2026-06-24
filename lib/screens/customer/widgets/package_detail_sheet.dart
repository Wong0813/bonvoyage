import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/wishlist_service.dart';
import '../../../utils/app_theme.dart';

class PackageDetailSheet extends StatelessWidget {
  final UserModel currentUser;
  final TravelPackageModel pkg;
  final bool fromBooking;
  final List<ReviewModel> reviews;
  final double avgRating;
  final List<int> wishlistIds;
  final List<BookingModel> bookings;
  final VoidCallback onBack;
  final Function(List<int>) onWishlistChanged;
  final Function(TravelPackageModel) onBookPackage;
  final Function(BookingModel) onPayBooking;
  final Function(BookingModel) onAddReview;

  const PackageDetailSheet({
    super.key,
    required this.currentUser,
    required this.pkg,
    required this.fromBooking,
    required this.reviews,
    required this.avgRating,
    required this.wishlistIds,
    required this.bookings,
    required this.onBack,
    required this.onWishlistChanged,
    required this.onBookPackage,
    required this.onPayBooking,
    required this.onAddReview,
  });

  @override
  Widget build(BuildContext context) {
    final isWish = wishlistIds.contains(pkg.id);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: onBack,
        ),
        title: Text(pkg.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isWish ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
            onPressed: () async {
              await WishlistService.instance.toggle(currentUser.id, pkg.id);
              final wishIds = await WishlistService.instance.getPackageIdsByUser(currentUser.id);
              onWishlistChanged(wishIds);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pkg.images.isEmpty)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_search_rounded, size: 60, color: Colors.white30),
                      SizedBox(height: 8),
                      Text('No package images uploaded', style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pkg.images.length,
                  itemBuilder: (context, i) {
                    final path = pkg.images[i].imagePath;
                    final Widget imageWidget = AppTheme.imageFromPath(
                      path,
                      fit: BoxFit.cover,
                      errorWidget: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 40),
                      ),
                    );
                    return Container(
                      width: MediaQuery.of(context).size.width > 750 ? 350 : 280,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageWidget,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Text(pkg.destination, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                StarRating(rating: avgRating, size: 16),
                const SizedBox(width: 8),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  ' (${reviews.length} reviews)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF00D4FF), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Travel Date: ${pkg.travelDate.toIso8601String().split("T").first}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF4ECDC4), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Type: ${pkg.tripType.toUpperCase()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.category_rounded, color: Color(0xFFFF6B9D), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Category: ${pkg.category}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(pkg.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            const Text('Attractions:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(pkg.attractions, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price per person', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    if (pkg.hasPromotion) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'RM ${pkg.promoPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'RM ${pkg.pricePerPerson.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white38, fontSize: 13, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ),
                    ] else
                      Text('RM ${pkg.pricePerPerson.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (fromBooking)
                  _buildBookingAction()
                else
                  ElevatedButton(
                    onPressed: () => onBookPackage(pkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Book This Package', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reviews:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            reviews.isEmpty
                ? const Text('No reviews yet.', style: TextStyle(color: Colors.white38))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (ctx, i) {
                      final r = reviews[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.username, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                Row(
                                  children: List.generate(5, (index) => Icon(Icons.star, color: index < r.rating ? Colors.amber : Colors.white10, size: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.comment, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingAction() {
    final relevantBookings = bookings.where((b) => b.packageId == pkg.id).toList();
    if (relevantBookings.isEmpty) {
      return ElevatedButton(
        onPressed: () => onBookPackage(pkg),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4FF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Book This Package', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      );
    }
    final b = relevantBookings.first;
    final isUnpaid = b.paymentStatus == 'pending';
    final canWriteReview = b.canReview && b.paymentStatus == 'paid';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              b.status.toUpperCase(),
              style: TextStyle(
                color: b.status == 'confirmed'
                    ? Colors.greenAccent
                    : b.status == 'completed'
                        ? Colors.lightBlueAccent
                        : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text('Booking ID: #${b.id}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(width: 16),
        if (isUnpaid)
          ElevatedButton(
            onPressed: () => onPayBooking(b),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          )
        else if (canWriteReview)
          ElevatedButton.icon(
            onPressed: () => onAddReview(b),
            icon: const Icon(Icons.rate_review_rounded, size: 16, color: Colors.white),
            label: const Text('Write Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
}
