import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/agent_profile_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/travel_package_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

import 'views/packages_view.dart';
import 'views/bookings_view.dart';
import 'views/reviews_view.dart';
import 'views/company_profile_view.dart';
import 'views/chat_view.dart';
import 'widgets/package_form_dialog.dart';

class AgentHome extends StatefulWidget {
  final UserModel user;
  const AgentHome({super.key, required this.user});

  @override
  State<AgentHome> createState() => _AgentHomeState();
}

class _AgentHomeState extends State<AgentHome> {
  int _tab = 0;
  bool _loading = true;
  AgentProfileModel? _profile;
  List<TravelPackageModel> _packages = [];
  List<BookingModel> _bookings = [];
  List<ReviewModel> _reviews = [];
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await AgentProfileService.instance.getByUserId(widget.user.id)
          .timeout(const Duration(seconds: 15));
      if (profile == null) throw Exception('Agent profile not found');

      final pkgs = await TravelPackageService.instance.getPackages(
        filter: PackageFilter(agentId: profile.id),
      ).timeout(const Duration(seconds: 15));

      final bookings = await BookingService.instance.getBookingsByAgent(profile.id)
          .timeout(const Duration(seconds: 15));

      final reviews = await ReviewService.instance.getReviews(agentId: profile.id)
          .timeout(const Duration(seconds: 15));

      final notifs = await NotificationService.instance.getForAgent(profile.id)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _packages = pkgs;
        _bookings = bookings;
        _reviews = reviews;
        _notifications = notifs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, '$e', isError: true);
    }
  }

  void _showAddPackageForm() {
    showDialog(
      context: context,
      builder: (context) => PackageFormDialog(
        profile: _profile!,
        onSaved: _load,
      ),
    );
  }

  void _showEditPackageForm(TravelPackageModel pkg) {
    showDialog(
      context: context,
      builder: (context) => PackageFormDialog(
        pkg: pkg,
        profile: _profile!,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deletePackage(TravelPackageModel pkg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text('Delete Package?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the package for ${pkg.destination}?', style: const TextStyle(color: Colors.white70)),
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
        await TravelPackageService.instance.deletePackage(pkg.id, _profile!.id);
        _load();
      } catch (e) {
        if (mounted) showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1C),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
      );
    }

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
                  const Icon(Icons.business_rounded, color: Color(0xFF00D4FF), size: 24),
                  const SizedBox(width: 8),
                  Text(_profile!.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _buildActiveTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_tab) {
      case 0:
        return PackagesView(
          packages: _packages,
          bookings: _bookings,
          reviews: _reviews,
          profile: _profile!,
          onAddPackage: _showAddPackageForm,
          onEditPackage: _showEditPackageForm,
          onDeletePackage: _deletePackage,
        );
      case 1:
        return BookingsView(
          bookings: _bookings,
          notifications: _notifications,
          profile: _profile!,
          onLoad: _load,
        );
      case 2:
        return ReviewsView(
          reviews: _reviews,
          profile: _profile!,
        );
      case 3:
        return CompanyProfileView(
          profile: _profile!,
          onLoad: _load,
        );
      case 4:
        return ChatView(
          user: widget.user,
        );
      default:
        return PackagesView(
          packages: _packages,
          bookings: _bookings,
          reviews: _reviews,
          profile: _profile!,
          onAddPackage: _showAddPackageForm,
          onEditPackage: _showEditPackageForm,
          onDeletePackage: _deletePackage,
        );
    }
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
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF00D4FF), size: 28),
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
                      'Agent Portal',
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
                  backgroundColor: const Color(0xFF00D4FF),
                  child: Text(
                    _profile!.companyName.isNotEmpty ? _profile!.companyName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile!.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AGENT',
                          style: TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(_profile!.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Row(
              children: [
                Expanded(child: Text(widget.user.email)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('AGENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _profile!.companyName.isNotEmpty ? _profile!.companyName[0].toUpperCase() : 'A',
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
      {'icon': Icons.luggage_outlined, 'title': 'My Packages', 'tab': 0},
      {'icon': Icons.book_online_outlined, 'title': 'Bookings', 'tab': 1},
      {'icon': Icons.star_outline_rounded, 'title': 'Reviews', 'tab': 2},
      {'icon': Icons.business_outlined, 'title': 'Company Profile', 'tab': 3},
      {'icon': Icons.chat_bubble_outline_rounded, 'title': 'Client Chat', 'tab': 4},
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
