import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/wishlist_service.dart';
import '../../../utils/app_theme.dart';

class WishlistView extends StatelessWidget {
  final UserModel user;
  final List<TravelPackageModel> packages;
  final List<int> wishlistIds;
  final Function(TravelPackageModel) onOpenPackage;
  final VoidCallback onLoad;

  const WishlistView({
    super.key,
    required this.user,
    required this.packages,
    required this.wishlistIds,
    required this.onOpenPackage,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final wishlisted = packages.where((p) => wishlistIds.contains(p.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Wishlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        wishlisted.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Your wishlist is empty.', style: TextStyle(color: Colors.white38))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wishlisted.length,
                itemBuilder: (context, idx) {
                  final pkg = wishlisted[idx];
                  return Stack(
                    children: [
                      _packageCard(context, pkg),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.redAccent),
                          onPressed: () async {
                            await WishlistService.instance.toggle(user.id, pkg.id);
                            onLoad();
                          },
                        ),
                      )
                    ],
                  );
                },
              )
      ],
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
}
