import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';

class ProfileDialog extends StatefulWidget {
  final UserModel currentUser;
  final Function(UserModel) onProfileUpdated;
  final VoidCallback onLogout;

  const ProfileDialog({
    super.key,
    required this.currentUser,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _icPassportCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.currentUser.username);
    _emailCtrl = TextEditingController(text: widget.currentUser.email);
    _fullNameCtrl = TextEditingController(text: widget.currentUser.fullName);
    _phoneCtrl = TextEditingController(text: widget.currentUser.phone ?? '');
    _icPassportCtrl = TextEditingController(text: widget.currentUser.icPassport ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _icPassportCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.currentUser.username.substring(0, 2).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.currentUser.fullName.isNotEmpty ? widget.currentUser.fullName : widget.currentUser.username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.currentUser.memberId ?? 'Explorer',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameCtrl,
                readOnly: true,
                decoration: AppTheme.input('Username'),
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailCtrl,
                readOnly: true,
                decoration: AppTheme.input('Email'),
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _fullNameCtrl,
                decoration: AppTheme.input('Full Name'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneCtrl,
                decoration: AppTheme.input('Phone'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _icPassportCtrl,
                decoration: AppTheme.input('IC / Passport'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _loading = true);
                      try {
                        final ok = await AuthService.instance.updateProfile(
                          userId: widget.currentUser.id,
                          fullName: _fullNameCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          icPassport: _icPassportCtrl.text.trim(),
                        );
                        if (ok) {
                          final updatedUser = await AuthService.instance.getUserById(widget.currentUser.id);
                          if (updatedUser != null) {
                            widget.onProfileUpdated(updatedUser);
                          }
                          if (mounted) showAppSnackBar(context, 'Profile updated successfully!');
                          Navigator.pop(context);
                        } else {
                          throw Exception('Failed to update profile');
                        }
                      } catch (e) {
                        if (mounted) showAppSnackBar(context, '$e', isError: true);
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLogout();
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                    label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
