import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/promotion_service.dart';
import '../../../utils/app_theme.dart';

class PromotionFormDialog extends StatefulWidget {
  final PromotionModel? promo;
  final List<TravelPackageModel> packages;
  final VoidCallback onSaved;

  const PromotionFormDialog({
    super.key,
    this.promo,
    required this.packages,
    required this.onSaved,
  });

  @override
  State<PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<PromotionFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _discCtrl;
  int? _selectedPackageId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.promo?.title);
    _descCtrl = TextEditingController(text: widget.promo?.description);
    _discCtrl = TextEditingController(text: widget.promo != null ? widget.promo!.discountPercent?.toStringAsFixed(0) : '15');
    _selectedPackageId = widget.promo?.packageId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final disc = double.tryParse(_discCtrl.text);

    if (title.isEmpty || desc.isEmpty || disc == null) {
      showAppSnackBar(context, 'Please fill in all required fields.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.promo == null) {
        await PromotionService.instance.create(
          title: title,
          description: desc,
          discountPercent: disc,
          packageId: _selectedPackageId,
        );
        if (mounted) showAppSnackBar(context, 'Promotion created successfully!');
      } else {
        await PromotionService.instance.update(
          id: widget.promo!.id,
          title: title,
          description: desc,
          discountPercent: disc,
          packageId: _selectedPackageId,
        );
        if (mounted) showAppSnackBar(context, 'Promotion updated successfully!');
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16162A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      title: Text(
        widget.promo == null ? 'Create New Promotion' : 'Edit Promotion Details',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleCtrl, decoration: AppTheme.input('Promo Title *'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _descCtrl, decoration: AppTheme.input('Promo Description *'), maxLines: 2, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _discCtrl, decoration: AppTheme.input('Discount Percentage (%) *'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _selectedPackageId,
                dropdownColor: const Color(0xFF16162A),
                decoration: AppTheme.input('Target Travel Package (optional)'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Global Promotion (No Package)', style: TextStyle(color: Colors.white30, fontSize: 13)),
                  ),
                  ...widget.packages.map((pkg) => DropdownMenuItem<int?>(
                        value: pkg.id,
                        child: Text(pkg.destination, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedPackageId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.promo == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
