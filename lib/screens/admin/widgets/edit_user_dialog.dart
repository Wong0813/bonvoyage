import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/admin_service.dart';
import '../../../utils/app_theme.dart';

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onSaved;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onSaved,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _fullNameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final fullName = _fullNameCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || fullName.isEmpty) {
      showAppSnackBar(context, 'Required fields cannot be empty.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await AdminService.instance.updateUser(
        userId: widget.user.id,
        username: username,
        email: email,
        fullName: fullName,
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) showAppSnackBar(context, 'User updated successfully!');
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
      title: Row(
        children: [
          const Icon(Icons.edit_rounded, color: Color(0xFF00D4FF)),
          const SizedBox(width: 10),
          Text(
            'Edit ${widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.username}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _fullNameCtrl, decoration: AppTheme.input('Full Name'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              TextField(controller: _usernameCtrl, decoration: AppTheme.input('Username'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              TextField(controller: _emailCtrl, decoration: AppTheme.input('Email Address'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              TextField(controller: _phoneCtrl, decoration: AppTheme.input('Phone'), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
