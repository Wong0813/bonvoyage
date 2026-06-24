import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/promotion_service.dart';
import '../../../services/voucher_service.dart';

class PromotionsView extends StatelessWidget {
  final List<VoucherModel> vouchers;
  final List<PromotionModel> promotions;
  final VoidCallback onCreateVoucher;
  final VoidCallback onNewPromotion;
  final VoidCallback onRefresh;
  final Function(VoucherModel) onEditVoucher;
  final Function(VoucherModel) onDeleteVoucher;
  final Function(PromotionModel) onEditPromotion;
  final Function(PromotionModel) onDeletePromotion;

  const PromotionsView({
    super.key,
    required this.vouchers,
    required this.promotions,
    required this.onCreateVoucher,
    required this.onNewPromotion,
    required this.onRefresh,
    required this.onEditVoucher,
    required this.onDeleteVoucher,
    required this.onEditPromotion,
    required this.onDeletePromotion,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Promotions & Vouchers Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCreateVoucher,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Voucher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onNewPromotion,
                icon: const Icon(Icons.campaign_rounded, size: 18),
                label: const Text('New Promotion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('Discount Vouchers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (vouchers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text('No active discount vouchers found.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ),
          ),
        ...vouchers.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF00D4FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF00D4FF), size: 20),
                ),
                title: Text(v.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  'Discount: ${v.discountValue}${v.discountType == 'percent' ? '%' : ' RM'}  |  Redeemed: ${v.usedCount} / ${v.maxUses}  |  Min Purchase: RM ${v.minPurchase.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      activeColor: const Color(0xFF00D4FF),
                      value: v.status == 'active',
                      onChanged: (on) async {
                        await VoucherService.instance.updateStatus(v.id, on ? 'active' : 'inactive');
                        onRefresh();
                      },
                    ),
                    const SizedBox(width: 8),
                    _tableActionBtn(Icons.edit_rounded, const Color(0xFF00D4FF), 'Edit Voucher', () => onEditVoucher(v)),
                    const SizedBox(width: 6),
                    _tableActionBtn(Icons.delete_rounded, Colors.redAccent, 'Delete Voucher', () => onDeleteVoucher(v)),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 24),
        const Text('Global Promotions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (promotions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text('No active promotions running.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ),
          ),
        ...promotions.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.percent_rounded, color: Color(0xFF6C63FF), size: 20),
                ),
                title: Row(
                  children: [
                    Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    _buildPromotionStatusBadge(p),
                  ],
                ),
                subtitle: Text(
                  '${p.description}  |  Discount: ${p.discountPercent}%${p.packageDestination != null ? '  |  Target: ${p.packageDestination}' : ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      activeColor: const Color(0xFF6C63FF),
                      value: p.status == 'active',
                      onChanged: (on) async {
                        await PromotionService.instance.updateStatus(p.id, on ? 'active' : 'inactive');
                        onRefresh();
                      },
                    ),
                    const SizedBox(width: 8),
                    _tableActionBtn(Icons.edit_rounded, const Color(0xFF00D4FF), 'Edit Promotion', () => onEditPromotion(p)),
                    const SizedBox(width: 6),
                    _tableActionBtn(Icons.delete_rounded, Colors.redAccent, 'Delete Promotion', () => onDeletePromotion(p)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPromotionStatusBadge(PromotionModel p) {
    if (p.status != 'active') {
      return _badge('INACTIVE', Colors.white30, Colors.white54);
    }
    final now = DateTime.now();
    if (p.validFrom != null && now.isBefore(p.validFrom!)) {
      return _badge('SCHEDULED', Colors.amber.withValues(alpha: 0.15), Colors.amberAccent);
    }
    if (p.validUntil != null && now.isAfter(p.validUntil!.add(const Duration(days: 1)))) {
      return _badge('EXPIRED', Colors.red.withValues(alpha: 0.15), Colors.redAccent);
    }
    return _badge('RUNNING', Colors.green.withValues(alpha: 0.15), Colors.greenAccent);
  }

  Widget _badge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _tableActionBtn(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
