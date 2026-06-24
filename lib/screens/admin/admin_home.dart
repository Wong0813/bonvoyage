import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../services/review_service.dart';
import '../../services/travel_package_service.dart';
import '../../services/voucher_service.dart';
import '../../services/promotion_service.dart';
import '../../services/agent_profile_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

// Views
import 'views/dashboard_view.dart';
import 'views/account_list_view.dart';
import 'views/packages_view.dart';
import 'views/reviews_view.dart';
import 'views/promotions_view.dart';
import 'views/broadcast_view.dart';

// Widgets
import 'widgets/add_user_dialog.dart';
import 'widgets/edit_user_dialog.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/voucher_form_dialog.dart';
import 'widgets/promotion_form_dialog.dart';
import 'widgets/admin_package_form_dialog.dart';

class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tab = 0;
  bool _loading = true;
  Map<String, int> _stats = {};
  List<UserModel> _users = [];
  List<UserModel> _agents = [];
  List<TravelPackageModel> _packages = [];
  List<ReviewModel> _reviews = [];
  List<Map<String, dynamic>> _reports = [];
  List<VoucherModel> _vouchers = [];
  List<PromotionModel> _promotions = [];
  List<AgentProfileModel> _agentProfiles = [];

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await AdminService.instance.getDashboardStats();
      final users = await AdminService.instance.getAllUsers(role: 'user');
      final agents = await AdminService.instance.getAllUsers(role: 'agent');
      final packages = await TravelPackageService.instance.getAllPackagesAdmin();
      final reviews = await ReviewService.instance.getReviews();
      final reports = await ReviewService.instance.getReports();
      final vouchers = await VoucherService.instance.getAll();
      final promotions = await PromotionService.instance.getAll();
      final agentProfiles = await AgentProfileService.instance.getAll();

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _users = users;
        _agents = agents;
        _packages = packages;
        _reviews = reviews;
        _reports = reports;
        _vouchers = vouchers;
        _promotions = promotions;
        _agentProfiles = agentProfiles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, '$e', isError: true);
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (_) => AddUserDialog(onSaved: _load),
    );
  }

  void _showEditUserDialog(UserModel u) {
    showDialog(
      context: context,
      builder: (_) => EditUserDialog(user: u, onSaved: _load),
    );
  }

  void _showChangePasswordDialog(UserModel u) {
    showDialog(
      context: context,
      builder: (_) => ChangePasswordDialog(user: u),
    );
  }

  void _showDeleteConfirmDialog(UserModel u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                      child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.fullName.isNotEmpty ? u.fullName : u.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${u.email} • ${u.role.toUpperCase()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to permanently delete this account? This will remove all associated data including bookings, reviews, chat messages, and packages.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              try {
                await AdminService.instance.deleteUser(u.id);
                if (ctx.mounted) Navigator.pop(ctx);
                showAppSnackBar(context, 'Account deleted permanently.');
                _load();
              } catch (e) {
                if (ctx.mounted) showAppSnackBar(ctx, '$e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportsNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B9D)),
            SizedBox(width: 10),
            Text('Complaints & Reports', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: _reports.isEmpty
            ? Text('All clear! There are no pending complaints or flagged reviews.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7)))
            : SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.04),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('Reason: ${report['reason'] ?? "N/A"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Comment: ${report['comment'] ?? ""}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.check, color: Colors.greenAccent, size: 20),
                          onPressed: () async {
                            await ReviewService.instance.moderateReview(report['reviewId'] as int, 'active');
                            if (ctx.mounted) Navigator.pop(ctx);
                            _load();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00D4FF))),
          )
        ],
      ),
    );
  }

  void _showPackageForm({TravelPackageModel? pkg}) {
    showDialog(
      context: context,
      builder: (_) => AdminPackageFormDialog(
        pkg: pkg,
        agentProfiles: _agentProfiles,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deletePackage(TravelPackageModel pkg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: const Text('Delete Package?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete the package for "${pkg.destination}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await TravelPackageService.instance.adminDeletePackage(pkg.id);
        if (mounted) showAppSnackBar(context, 'Package deleted successfully.');
        _load();
      } catch (e) {
        if (mounted) showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  void _showVoucherForm({VoucherModel? voucher}) {
    showDialog(
      context: context,
      builder: (_) => VoucherFormDialog(
        voucher: voucher,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deleteVoucher(VoucherModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: const Text('Delete Voucher?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete the voucher code "${v.code}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await VoucherService.instance.delete(v.id);
        if (mounted) showAppSnackBar(context, 'Voucher deleted successfully.');
        _load();
      } catch (e) {
        if (mounted) showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  void _showPromotionForm({PromotionModel? promo}) {
    showDialog(
      context: context,
      builder: (_) => PromotionFormDialog(
        promo: promo,
        packages: _packages,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deletePromotion(PromotionModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: const Text('Delete Promotion?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete the promotion "${p.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await PromotionService.instance.delete(p.id);
        if (mounted) showAppSnackBar(context, 'Promotion deleted successfully.');
        _load();
      } catch (e) {
        if (mounted) showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  Future<void> _moderateReview(int reviewId, String status) async {
    try {
      await ReviewService.instance.moderateReview(reviewId, status);
      _load();
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 950;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1C),
      drawer: isDesktop ? null : _buildDrawer(),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF16162A),
              title: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF6C63FF), size: 24),
                  const SizedBox(width: 8),
                  Text('BonVoyage Admin', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
                : IndexedStack(
                    index: _tab,
                    children: [
                      DashboardView(
                        stats: _stats,
                        users: _users,
                        agents: _agents,
                        reports: _reports,
                        searchCtrl: _searchCtrl,
                        searchQuery: _searchQuery,
                        onRefresh: _load,
                        onShowReports: _showReportsNotificationDialog,
                        onAddUser: _showAddUserDialog,
                        onBroadcast: () => setState(() => _tab = 6),
                        onCreateVoucher: _showVoucherForm,
                        onNewPromotion: _showPromotionForm,
                        onEditUser: _showEditUserDialog,
                        onChangePassword: _showChangePasswordDialog,
                        onDeleteUser: _showDeleteConfirmDialog,
                      ),
                      AccountListView(
                        accounts: _users,
                        title: 'Customers Directory',
                        roleType: 'user',
                        onAddAccount: _showAddUserDialog,
                        onRefresh: _load,
                        onEditAccount: _showEditUserDialog,
                        onChangePassword: _showChangePasswordDialog,
                        onDeleteAccount: _showDeleteConfirmDialog,
                      ),
                      AccountListView(
                        accounts: _agents,
                        title: 'Travel Agents Directory',
                        roleType: 'agent',
                        onAddAccount: _showAddUserDialog,
                        onRefresh: _load,
                        onEditAccount: _showEditUserDialog,
                        onChangePassword: _showChangePasswordDialog,
                        onDeleteAccount: _showDeleteConfirmDialog,
                      ),
                      PackagesView(
                        packages: _packages,
                        onAddPackage: () => _showPackageForm(),
                        onRefresh: _load,
                        onEditPackage: (pkg) => _showPackageForm(pkg: pkg),
                        onDeletePackage: _deletePackage,
                      ),
                      ReviewsView(
                        reviews: _reviews,
                        reports: _reports,
                        onRefresh: _load,
                        onModerate: _moderateReview,
                      ),
                      PromotionsView(
                        vouchers: _vouchers,
                        promotions: _promotions,
                        onCreateVoucher: () => _showVoucherForm(),
                        onNewPromotion: () => _showPromotionForm(),
                        onRefresh: _load,
                        onEditVoucher: (v) => _showVoucherForm(voucher: v),
                        onDeleteVoucher: _deleteVoucher,
                        onEditPromotion: (promo) => _showPromotionForm(promo: promo),
                        onDeletePromotion: _deletePromotion,
                      ),
                      const BroadcastView(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF111126),
        border: Border(right: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF00D4FF), size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BonVoyage',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    Text(
                      'Management',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFF6B9D),
                  child: Text(
                    widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName.isNotEmpty ? widget.user.fullName : 'System Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _sidebarItems(),
            ),
          ),
          const Divider(color: Colors.white10),
          _sidebarItem(Icons.logout, 'Logout', color: Colors.redAccent, onTap: () => logout(context)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF111126),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Row(
              children: [
                Expanded(child: Text(widget.user.email)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : 'A',
                style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _sidebarItems(closeDrawer: true),
            ),
          ),
          const Divider(color: Colors.white10),
          _sidebarItem(Icons.logout, 'Logout', color: Colors.redAccent, onTap: () {
            Navigator.pop(context);
            logout(context);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _sidebarItems({bool closeDrawer = false}) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.dashboard_outlined, 'title': 'Dashboard', 'tab': 0},
      {'icon': Icons.people_outline, 'title': 'Users', 'tab': 1},
      {'icon': Icons.business_outlined, 'title': 'Agents', 'tab': 2},
      {'icon': Icons.luggage_outlined, 'title': 'Packages', 'tab': 3},
      {'icon': Icons.rate_review_outlined, 'title': 'Reviews', 'tab': 4},
      {'icon': Icons.local_offer_outlined, 'title': 'Promotions', 'tab': 5},
      {'icon': Icons.notifications_outlined, 'title': 'Broadcast', 'tab': 6},
    ];

    return items.map((item) {
      final bool isSelected = _tab == item['tab'];
      return _sidebarItem(
        item['icon'] as IconData,
        item['title'] as String,
        isSelected: isSelected,
        onTap: () {
          setState(() => _tab = item['tab'] as int);
          if (closeDrawer) Navigator.pop(context);
        },
      );
    }).toList();
  }

  Widget _sidebarItem(IconData icon, String title, {bool isSelected = false, Color? color, VoidCallback? onTap}) {
    final activeColor = color ?? const Color(0xFF00D4FF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? activeColor : (color ?? Colors.white70), size: 22),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? activeColor : (color ?? Colors.white70),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
