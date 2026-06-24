import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/app_theme.dart';

class PackagesView extends StatelessWidget {
  final List<TravelPackageModel> packages;
  final VoidCallback onAddPackage;
  final VoidCallback onRefresh;
  final Function(TravelPackageModel) onEditPackage;
  final Function(TravelPackageModel) onDeletePackage;

  const PackagesView({
    super.key,
    required this.packages,
    required this.onAddPackage,
    required this.onRefresh,
    required this.onEditPackage,
    required this.onDeletePackage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Travel Packages Administration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onAddPackage,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00D4FF)), onPressed: onRefresh),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (packages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text('No travel packages uploaded by any agents yet.', style: TextStyle(color: Colors.white24, fontSize: 14)),
            ),
          ),
        ...packages.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF00D4FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.luggage, color: Color(0xFF00D4FF), size: 22),
              ),
              title: Text(p.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Agent: ${p.companyName} (${p.agentCode})  |  Price: ${formatCurrency(p.effectivePrice)}  |  Status: ${p.status.toUpperCase()}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tableActionBtn(Icons.edit_rounded, const Color(0xFF00D4FF), 'Edit Package', () => onEditPackage(p)),
                  const SizedBox(width: 6),
                  _tableActionBtn(Icons.delete_rounded, Colors.redAccent, 'Delete Package', () => onDeletePackage(p)),
                ],
              ),
            ),
          );
        }),
      ],
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
