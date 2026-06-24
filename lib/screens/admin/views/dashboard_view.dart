import 'package:flutter/material.dart';
import '../../../models/models.dart';

class DashboardView extends StatelessWidget {
  final Map<String, int> stats;
  final List<UserModel> users;
  final List<UserModel> agents;
  final List<Map<String, dynamic>> reports;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final VoidCallback onRefresh;
  final VoidCallback onShowReports;
  final VoidCallback onAddUser;
  final VoidCallback onBroadcast;
  final VoidCallback onCreateVoucher;
  final VoidCallback onNewPromotion;
  final Function(UserModel) onEditUser;
  final Function(UserModel) onChangePassword;
  final Function(UserModel) onDeleteUser;

  const DashboardView({
    super.key,
    required this.stats,
    required this.users,
    required this.agents,
    required this.reports,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onRefresh,
    required this.onShowReports,
    required this.onAddUser,
    required this.onBroadcast,
    required this.onCreateVoucher,
    required this.onNewPromotion,
    required this.onEditUser,
    required this.onChangePassword,
    required this.onDeleteUser,
  });

  @override
  Widget build(BuildContext context) {
    final List<UserModel> allAccounts = [...users, ...agents];
    final List<UserModel> filteredAccounts = allAccounts.where((u) {
      final name = u.fullName.toLowerCase();
      final username = u.username.toLowerCase();
      final email = u.email.toLowerCase();
      return name.contains(searchQuery) || username.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF16162A),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 24),
          _buildStatsGrid(context),
          const SizedBox(height: 28),
          _buildQuickActions(),
          const SizedBox(height: 28),
          _buildUserTableSection(filteredAccounts),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    final int unreadReports = reports.length;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search users, email, role or username...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white70),
                onPressed: onShowReports,
              ),
            ),
            if (unreadReports > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      '$unreadReports',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final int totalUsers = (stats['users'] ?? 0) + (stats['agents'] ?? 0);
    final int bookings = stats['bookings'] ?? 0;
    final int revenue = stats['revenue'] ?? 0;
    final int complaints = stats['reports'] ?? 0;

    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 950;
    final double contentWidth = isDesktop ? (width - 260) : width;

    int crossAxisCount = 2;
    if (contentWidth >= 800) {
      crossAxisCount = 4;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: crossAxisCount == 4 ? 1.4 : 1.6,
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: '$totalUsers',
          subtitle: 'Customers & Agents',
          icon: Icons.people_rounded,
          gradient: const [Color(0xFF00c6ff), Color(0xFF0072ff)],
        ),
        _buildStatCard(
          title: 'Bookings',
          value: '$bookings',
          subtitle: 'Total reserved trips',
          icon: Icons.shopping_bag_rounded,
          gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        _buildStatCard(
          title: 'Revenue',
          value: 'RM $revenue',
          subtitle: 'Paid bookings total',
          icon: Icons.monetization_on_rounded,
          gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
        ),
        _buildStatCard(
          title: 'Complaints',
          value: '$complaints',
          subtitle: 'Flagged review items',
          icon: Icons.warning_rounded,
          gradient: const [Color(0xFFf857a6), Color(0xFFff5858)],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    Icon(icon, color: Colors.white, size: 20),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Operations',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionChip(
                label: 'Add New Account',
                icon: Icons.person_add_rounded,
                color: const Color(0xFF4ECDC4),
                onTap: onAddUser,
              ),
              _actionChip(
                label: 'Broadcast Announcement',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF6C63FF),
                onTap: onBroadcast,
              ),
              _actionChip(
                label: 'Create Voucher Code',
                icon: Icons.add_card_rounded,
                color: const Color(0xFF00D4FF),
                onTap: onCreateVoucher,
              ),
              _actionChip(
                label: 'New Promotion',
                icon: Icons.local_offer_rounded,
                color: const Color(0xFFFF6B9D),
                onTap: onNewPromotion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTableSection(List<UserModel> filteredAccounts) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Management Directory',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      'Total: ${filteredAccounts.length}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onAddUser,
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (filteredAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No users found matching search query.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
                horizontalMargin: 20,
                columnSpacing: 30,
                columns: const [
                  DataColumn(label: Text('Avatar / Name', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Email Address', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Role', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Member ID', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold))),
                ],
                rows: filteredAccounts.map((u) {
                  Color roleColor = const Color(0xFF6C63FF);
                  if (u.isAdmin) roleColor = const Color(0xFFFF6B9D);
                  if (u.isAgent) roleColor = const Color(0xFF00D4FF);

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: roleColor.withValues(alpha: 0.15),
                              child: Text(
                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              u.fullName.isNotEmpty ? u.fullName : u.username,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(u.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            u.role.toUpperCase(),
                            style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                      DataCell(Text(u.memberId ?? 'N/A', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _tableActionBtn(Icons.edit_rounded, const Color(0xFF00D4FF), 'Edit', () => onEditUser(u)),
                            const SizedBox(width: 4),
                            _tableActionBtn(Icons.lock_reset_rounded, const Color(0xFFFFD200), 'Password', () => onChangePassword(u)),
                            const SizedBox(width: 4),
                            if (!u.isAdmin)
                              _tableActionBtn(Icons.delete_rounded, Colors.redAccent, 'Delete', () => onDeleteUser(u)),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
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
