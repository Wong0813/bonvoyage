import 'package:flutter/material.dart';
import '../../../models/models.dart';

class AccountListView extends StatelessWidget {
  final List<UserModel> accounts;
  final String title;
  final String roleType;
  final VoidCallback onAddAccount;
  final VoidCallback onRefresh;
  final Function(UserModel) onEditAccount;
  final Function(UserModel) onChangePassword;
  final Function(UserModel) onDeleteAccount;

  const AccountListView({
    super.key,
    required this.accounts,
    required this.title,
    required this.roleType,
    required this.onAddAccount,
    required this.onRefresh,
    required this.onEditAccount,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00D4FF)),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                'No ${roleType == 'agent' ? 'agents' : 'customers'} found.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
              ),
            ),
          )
        else
          ...accounts.map((u) {
            final Color accentColor = u.isAgent ? const Color(0xFF00D4FF) : const Color(0xFF6C63FF);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  '${u.fullName.isNotEmpty ? u.fullName : u.username} (${u.username})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Email: ${u.email}  •  ID: ${u.memberId ?? "N/A"}${u.phone != null && u.phone!.isNotEmpty ? '  •  Phone: ${u.phone}' : ''}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tableActionBtn(Icons.edit_rounded, const Color(0xFF00D4FF), 'Edit', () => onEditAccount(u)),
                    const SizedBox(width: 6),
                    _tableActionBtn(Icons.lock_reset_rounded, const Color(0xFFFFD200), 'Change Password', () => onChangePassword(u)),
                    const SizedBox(width: 6),
                    _tableActionBtn(Icons.delete_rounded, Colors.redAccent, 'Delete', () => onDeleteAccount(u)),
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
