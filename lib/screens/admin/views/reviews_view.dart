import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ReviewsView extends StatelessWidget {
  final List<ReviewModel> reviews;
  final List<Map<String, dynamic>> reports;
  final VoidCallback onRefresh;
  final Function(int, String) onModerate;

  const ReviewsView({
    super.key,
    required this.reviews,
    required this.reports,
    required this.onRefresh,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews & Report Moderation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00D4FF)), onPressed: onRefresh),
          ],
        ),
        const SizedBox(height: 16),
        if (reports.isNotEmpty) ...[
          const Text('Pending Abuse Reports', style: TextStyle(color: Color(0xFFFF6B9D), fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...reports.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF6B9D).withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  title: Text('Report on review #${r['reviewId']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Reporter: ${r['reporter']} · Reason: ${r['reason']}\nComment: "${r['comment']}"', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => onModerate(r['reviewId'] as int, 'removed'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 20),
                        onPressed: () => onModerate(r['reviewId'] as int, 'active'),
                      ),
                    ],
                  ),
                ),
              )),
          const Divider(color: Colors.white24, height: 32),
        ],
        const Text('All Reviews Directory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text('No reviews have been written yet.', style: TextStyle(color: Colors.white24, fontSize: 14)),
            ),
          ),
        ...reviews.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                title: Row(
                  children: [
                    Text(r.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('${r.rating} ⭐', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                subtitle: Text(
                  'Destination: ${r.destination}  |  Company: ${r.companyName}\nComment: "${r.comment}"',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
                trailing: r.status == 'reported'
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('REPORTED', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                      )
                    : null,
              ),
            )),
      ],
    );
  }
}
