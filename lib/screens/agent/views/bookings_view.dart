import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';

class BookingsView extends StatelessWidget {
  final List<BookingModel> bookings;
  final List<NotificationModel> notifications;
  final AgentProfileModel profile;
  final VoidCallback onLoad;

  const BookingsView({
    super.key,
    required this.bookings,
    required this.notifications,
    required this.profile,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = notifications.where((n) => !n.isRead).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (unreadNotifs.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Alerts', style: TextStyle(color: Color(0xFFFF6B9D), fontWeight: FontWeight.bold, fontSize: 14)),
              TextButton(
                onPressed: () async {
                  await NotificationService.instance.markAllRead(agentId: profile.id);
                  onLoad();
                },
                child: const Text('Mark All as Read', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...unreadNotifs.take(2).map((n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6B9D).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFFF6B9D), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(n.message, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: Colors.white10, height: 32),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Customer Reservation Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00D4FF)), onPressed: onLoad),
          ],
        ),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text('No reservation requests received yet.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ),
          )
        else
          ...bookings.map((b) {
            Color statusColor = Colors.orangeAccent;
            if (b.status == 'confirmed') statusColor = Colors.greenAccent;
            if (b.status == 'completed') statusColor = const Color(0xFF00D4FF);
            if (b.status == 'cancelled') statusColor = Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  '${b.destination} — ${b.username}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Guest: ${b.guestName}  |  People: ${b.numPeople} pax\nTotal Price: RM ${b.totalPrice.toStringAsFixed(2)}\nPayment: ${b.paymentStatus.toUpperCase()}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                      color: const Color(0xFF16162A),
                      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                      onSelected: (v) async {
                        await BookingService.instance.updateBookingStatus(b.id, v.toString(), agentId: profile.id);
                        onLoad();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'confirmed', child: Text('Confirm Order', style: TextStyle(color: Colors.white, fontSize: 13))),
                        const PopupMenuItem(value: 'completed', child: Text('Mark Completed', style: TextStyle(color: Colors.white, fontSize: 13))),
                        const PopupMenuItem(value: 'cancelled', child: Text('Cancel Order', style: TextStyle(color: Colors.redAccent, fontSize: 13))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
