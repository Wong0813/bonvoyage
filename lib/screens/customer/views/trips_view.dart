import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/app_theme.dart';

class TripsView extends StatelessWidget {
  final UserModel user;
  final List<BookingModel> bookings;
  final List<TravelPackageModel> allPackages;
  final Function(TravelPackageModel, {bool fromBooking}) onOpenPackage;
  final VoidCallback onLoad;
  final Function(BookingModel) onPayBooking;
  final Function(BookingModel) onAddReview;

  const TripsView({
    super.key,
    required this.user,
    required this.bookings,
    required this.allPackages,
    required this.onOpenPackage,
    required this.onLoad,
    required this.onPayBooking,
    required this.onAddReview,
  });

  TravelPackageModel? _findPackageById(int packageId) {
    try {
      return allPackages.firstWhere((p) => p.id == packageId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        bookings.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No bookings yet', style: TextStyle(color: Colors.white38))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, idx) {
                  final b = bookings[idx];
                  final isUnpaid = b.paymentStatus == 'pending';
                  final canWriteReview = b.canReview && b.paymentStatus == 'paid';
                  final pkg = _findPackageById(b.packageId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: InkWell(
                      onTap: pkg != null ? () => onOpenPackage(pkg, fromBooking: true) : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                         padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                AppTheme.buildPackageImage(
                                  pkg?.images ?? const [],
                                  size: 48,
                                  radius: 12,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('Travel Date: ${b.travelDate.toIso8601String().split('T').first}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: b.status == 'completed'
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : b.status == 'confirmed'
                                            ? Colors.green.withValues(alpha: 0.2)
                                            : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    b.status.toUpperCase(),
                                    style: TextStyle(
                                      color: b.status == 'completed'
                                          ? Colors.blue
                                          : b.status == 'confirmed'
                                              ? Colors.green
                                              : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Guests: ${b.numPeople} | Total Price', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    Text('RM ${b.totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (isUnpaid)
                                      ElevatedButton(
                                        onPressed: () => onPayBooking(b),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                        child: const Text('Pay Now', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                                      ),
                                    if (canWriteReview)
                                      ElevatedButton(
                                        onPressed: () => onAddReview(b),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                        child: const Text('Review', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
      ],
    );
  }
}
