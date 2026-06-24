import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../utils/app_theme.dart';

class AddUserDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const AddUserDialog({
    super.key,
    required this.onSaved,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedRole = 'user';
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyNameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final email = _emailCtrl.text.trim();
    final fullName = _fullNameCtrl.text.trim();
    final companyName = _companyNameCtrl.text.trim();

    if (username.isEmpty || password.isEmpty || email.isEmpty || fullName.isEmpty) {
      showAppSnackBar(context, 'Please fill in all required fields.', isError: true);
      return;
    }
    if (password.length < 6) {
      showAppSnackBar(context, 'Password must be at least 6 characters long.', isError: true);
      return;
    }
    if (_selectedRole == 'agent' && companyName.isEmpty) {
      showAppSnackBar(context, 'Company Name is required for Travel Agents.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final ok = await AdminService.instance.createUser(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
        role: _selectedRole,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        companyName: companyName.isNotEmpty ? companyName : null,
        location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
      );
      if (ok) {
        if (mounted) showAppSnackBar(context, 'Account created successfully!');
        widget.onSaved();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) showAppSnackBar(context, 'Username or email already exists.', isError: true);
      }
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
          Icon(Icons.person_add_rounded, color: Color(0xFF00D4FF)),
          SizedBox(width: 10),
          Text('Add New Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '* indicates a required field',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: const Color(0xFF16162A),
                decoration: AppTheme.input('Account Role *'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Customer', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'agent', child: Text('Travel Agent', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setState(() => _selectedRole = v ?? 'user'),
              ),
              const SizedBox(height: 14),
              TextField(controller: _fullNameCtrl, decoration: AppTheme.input('Full Name *'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              TextField(controller: _usernameCtrl, decoration: AppTheme.input('Username *'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              TextField(controller: _emailCtrl, decoration: AppTheme.input('Email Address *'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                decoration: AppTheme.input('Password *').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  helperText: 'Must be at least 6 characters',
                  helperStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 14),
              TextField(controller: _phoneCtrl, decoration: AppTheme.input('Phone (optional)'), style: const TextStyle(color: Colors.white)),
              if (_selectedRole == 'agent') ...[
                const SizedBox(height: 14),
                TextField(controller: _companyNameCtrl, decoration: AppTheme.input('Company Name *'), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 14),
                TextField(controller: _locationCtrl, decoration: AppTheme.input('Office Location (optional)'), style: const TextStyle(color: Colors.white)),
              ],
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
              : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
