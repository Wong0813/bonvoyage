import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/voucher_service.dart';
import '../../../utils/app_theme.dart';

class VoucherFormDialog extends StatefulWidget {
  final VoucherModel? voucher;
  final VoidCallback onSaved;

  const VoucherFormDialog({
    super.key,
    this.voucher,
    required this.onSaved,
  });

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _valCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxUsesCtrl;
  late String _discountType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.voucher?.code);
    _valCtrl = TextEditingController(text: widget.voucher != null ? widget.voucher!.discountValue.toStringAsFixed(0) : '10');
    _minCtrl = TextEditingController(text: widget.voucher != null ? widget.voucher!.minPurchase.toStringAsFixed(0) : '0');
    _maxUsesCtrl = TextEditingController(text: widget.voucher != null ? widget.voucher!.maxUses.toString() : '100');
    _discountType = widget.voucher?.discountType ?? 'percent';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valCtrl.dispose();
    _minCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final val = double.tryParse(_valCtrl.text) ?? 10;
    final minPurchase = double.tryParse(_minCtrl.text) ?? 0;
    final maxUses = int.tryParse(_maxUsesCtrl.text) ?? 100;

    if (code.isEmpty) {
      showAppSnackBar(context, 'Code cannot be empty.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.voucher == null) {
        await VoucherService.instance.create(
          code: code,
          discountType: _discountType,
          discountValue: val,
          minPurchase: minPurchase,
          maxUses: maxUses,
        );
        if (mounted) showAppSnackBar(context, 'Voucher created successfully!');
      } else {
        await VoucherService.instance.update(
          id: widget.voucher!.id,
          code: code,
          discountType: _discountType,
          discountValue: val,
          minPurchase: minPurchase,
          maxUses: maxUses,
        );
        if (mounted) showAppSnackBar(context, 'Voucher updated successfully!');
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
        widget.voucher == null ? 'Create New Voucher' : 'Edit Voucher Details',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _codeCtrl, decoration: AppTheme.input('Coupon Code * (e.g. SUMMER26)'), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _discountType,
              dropdownColor: const Color(0xFF16162A),
              decoration: AppTheme.input('Discount Type *'),
              items: const [
                DropdownMenuItem(value: 'percent', child: Text('Percentage (%)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (RM)', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => setState(() => _discountType = v ?? 'percent'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _valCtrl, decoration: AppTheme.input('Discount Value *'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            TextField(controller: _minCtrl, decoration: AppTheme.input('Min Purchase Required (RM)'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            TextField(controller: _maxUsesCtrl, decoration: AppTheme.input('Max Uses Limit'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(widget.voucher == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
