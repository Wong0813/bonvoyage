import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ReviewsView extends StatelessWidget {
  final List<ReviewModel> reviews;
  final AgentProfileModel profile;

  const ReviewsView({
    super.key,
    required this.reviews,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFD200).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: Color(0xFFFFD200), size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Average Rating', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${profile.rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text('Reviews & Customer Feedbacks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text('No reviews have been written for your packages yet.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ),
          )
        else
          ...reviews.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Row(
                    children: [
                      Text(r.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 10),
                      Text('${r.rating} ⭐', style: const TextStyle(color: Color(0xFFFFD200), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Trip: ${r.destination}\n"${r.comment}"',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}
