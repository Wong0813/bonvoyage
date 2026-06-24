import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/admin_service.dart';
import '../../../utils/app_theme.dart';

class ChangePasswordDialog extends StatefulWidget {
  final UserModel user;

  const ChangePasswordDialog({
    super.key,
    required this.user,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass = _newPassCtrl.text;
    if (newPass.isEmpty) {
      showAppSnackBar(context, 'Password cannot be empty.', isError: true);
      return;
    }
    if (newPass.length < 6) {
      showAppSnackBar(context, 'Password must be at least 6 characters long.', isError: true);
      return;
    }
    if (newPass != _confirmPassCtrl.text) {
      showAppSnackBar(context, 'Passwords do not match.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await AdminService.instance.updateUserPassword(widget.user.id, newPass);
      if (mounted) showAppSnackBar(context, 'Password updated successfully!');
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
      title: const Row(
        children: [
          Icon(Icons.lock_reset_rounded, color: Color(0xFFFFD200)),
          SizedBox(width: 10),
          Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                    child: Text(
                      widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(widget.user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPassCtrl,
              decoration: AppTheme.input('New Password *').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                helperText: 'Must be at least 6 characters',
                helperStyle: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              obscureText: _obscureNew,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPassCtrl,
              decoration: AppTheme.input('Confirm Password *').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD200), foregroundColor: Colors.black),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
