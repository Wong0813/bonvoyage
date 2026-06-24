import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/travel_package_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/voucher_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

// Modular Views
import 'views/explore_view.dart';
import 'views/trips_view.dart';
import 'views/wishlist_view.dart';
import 'views/chat_view.dart';
import 'views/chat_page.dart';

// Modular Widgets
import 'widgets/package_detail_sheet.dart';
import 'widgets/notifications_dialog.dart';
import 'widgets/profile_dialog.dart';

class CustomerHome extends StatefulWidget {
  final UserModel user;
  const CustomerHome({super.key, required this.user});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  late UserModel _currentUser;
  int _selectedIndex = 0;
  bool _loading = true;
  List<TravelPackageModel> _packages = [];
  List<TravelPackageModel> _allPackages = [];
  List<BookingModel> _bookings = [];
  List<NotificationModel> _notifications = [];
  List<AgentProfileModel> _agents = [];
  List<int> _wishlistIds = [];
  int _unreadNotifs = 0;

  final _searchCtrl = TextEditingController();
  String _tripTypeFilter = 'all';
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCategory;

  // Selected Package details
  TravelPackageModel? _selectedPkg;
  bool _selectedPkgFromBooking = false;
  List<ReviewModel> _pkgReviews = [];
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = PackageFilter(
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        tripType: _tripTypeFilter == 'all' ? null : _tripTypeFilter,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      final pkgs = await TravelPackageService.instance.getPackages(filter: filter);
      final allPkgs = await TravelPackageService.instance.getPackages();
      final bookings = await BookingService.instance.getBookingsByUser(_currentUser.id);
      final notifs = await NotificationService.instance.getForUser(_currentUser.id);
      final unread = await NotificationService.instance.unreadCountForUser(_currentUser.id);
      final agents = await ChatService.instance.getAllAgentsForChat();
      final wishIds = await WishlistService.instance.getPackageIdsByUser(_currentUser.id);

      setState(() {
        _packages = pkgs;
        _allPackages = allPkgs;
        _bookings = bookings;
        _notifications = notifs;
        _unreadNotifs = unread;
        _agents = agents;
        _wishlistIds = wishIds;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  bool _matchesCategory(TravelPackageModel pkg, String category) {
    return pkg.category.toLowerCase() == category.toLowerCase();
  }

  Future<void> _openPackage(TravelPackageModel pkg, {bool fromBooking = false}) async {
    try {
      final reviews = await ReviewService.instance.getReviews(packageId: pkg.id);
      final avg = await ReviewService.instance.getAverageRating(pkg.id);
      setState(() {
        _selectedPkg = pkg;
        _selectedPkgFromBooking = fromBooking;
        _pkgReviews = reviews;
        _avgRating = avg;
      });
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 750;

    if (_selectedPkg != null) {
      return PackageDetailSheet(
        currentUser: _currentUser,
        pkg: _selectedPkg!,
        fromBooking: _selectedPkgFromBooking,
        reviews: _pkgReviews,
        avgRating: _avgRating,
        wishlistIds: _wishlistIds,
        bookings: _bookings,
        onBack: () => setState(() => _selectedPkg = null),
        onWishlistChanged: (wishlist) {
          setState(() {
            _wishlistIds = wishlist;
          });
        },
        onBookPackage: _bookPackageDialog,
        onPayBooking: _payBooking,
        onAddReview: _addReviewDialog,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: isMobile
          ? SafeArea(
              child: Column(
                children: [
                  _buildMobileTopBar(),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: _buildTabContent(),
                          ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopTopBar(),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: _buildTabContent(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        final filteredPkgs = _selectedCategory == null
            ? _packages
            : _packages.where((pkg) => _matchesCategory(pkg, _selectedCategory!)).toList();
        return ExploreView(
          user: _currentUser,
          packages: filteredPkgs,
          bookings: _bookings,
          onOpenPackage: _openPackage,
          onBookPackage: _bookPackageDialog,
          searchCtrl: _searchCtrl,
          onSearchChanged: (val) => _load(),
          onClearSearch: () {
            _searchCtrl.clear();
            setState(() {
              _selectedCategory = null;
            });
            _load();
          },
          selectedCategory: _selectedCategory,
          onCategoryChanged: (cat) {
            setState(() {
              _selectedCategory = cat;
            });
          },
        );
      case 1:
        return TripsView(
          user: _currentUser,
          bookings: _bookings,
          allPackages: _allPackages,
          onOpenPackage: _openPackage,
          onLoad: _load,
          onPayBooking: _payBooking,
          onAddReview: _addReviewDialog,
        );
      case 2:
        return WishlistView(
          user: _currentUser,
          packages: _allPackages,
          wishlistIds: _wishlistIds,
          onOpenPackage: _openPackage,
          onLoad: _load,
        );
      case 3:
        return ChatView(
          user: _currentUser,
          agents: _agents,
          onOpenChat: _openChatScreen,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMobileTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
              ),
            ),
            child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
            ).createShader(b),
            child: const Text(
              'BonVoyage',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showNotificationsDialog,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
                ),
                if (_unreadNotifs > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$_unreadNotifs', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showProfileDialog,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
                ),
              ),
              child: Center(
                child: Text(
                  _currentUser.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedIndex == 0
                      ? 'Explore'
                      : _selectedIndex == 1
                          ? 'My Trips'
                          : _selectedIndex == 2
                              ? 'Wishlist'
                              : 'Chat Support',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text(
                  _selectedIndex == 0
                      ? 'Where do you want to go?'
                      : 'Manage your travel settings and trips.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            if (_selectedIndex == 0)
              Container(
                width: 250,
                height: 40,
                margin: const EdgeInsets.only(right: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _load(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: AppTheme.input('Search destinations...').copyWith(
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _selectedCategory = null;
                              });
                              _load();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
            GestureDetector(
              onTap: _showNotificationsDialog,
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Positioned.fill(child: Icon(Icons.notifications_rounded, color: Colors.white, size: 20)),
                  if (_unreadNotifs > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$_unreadNotifs', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _showProfileDialog,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
                  ),
                ),
                child: Center(
                  child: Text(
                    _currentUser.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final navItems = [
      {'icon': Icons.explore_rounded, 'label': 'Explore'},
      {'icon': Icons.flight_rounded, 'label': 'My Trips'},
      {'icon': Icons.favorite_rounded, 'label': 'Wishlist'},
      {'icon': Icons.chat_rounded, 'label': 'Chat'},
    ];

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D24), Color(0xFF111128)],
        ),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)]),
                    ),
                    child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
                    ).createShader(b),
                    child: const Text(
                      'BonVoyage',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)]),
                    ),
                    child: Center(
                      child: Text(
                        _currentUser.username.substring(0, 2).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.fullName.isNotEmpty ? _currentUser.fullName : _currentUser.username,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          _currentUser.memberId ?? 'Explorer',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              navItems.length,
              (i) => _navItem(
                navItems[i]['icon'] as IconData,
                navItems[i]['label'] as String,
                i == _selectedIndex,
                () => setState(() => _selectedIndex = i),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 10),
                      Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    const accentColor = Color(0xFF00D4FF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? LinearGradient(
                    colors: [accentColor.withValues(alpha: 0.3), accentColor.withValues(alpha: 0.1)],
                  )
                : null,
            border: selected ? Border.all(color: accentColor.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? accentColor : Colors.white.withValues(alpha: 0.4), size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.explore_rounded, 'label': 'Explore'},
      {'icon': Icons.flight_rounded, 'label': 'Trips'},
      {'icon': Icons.favorite_rounded, 'label': 'Wishlist'},
      {'icon': Icons.chat_rounded, 'label': 'Chat'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D24),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == _selectedIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF00D4FF).withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: selected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        color: selected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (c) => NotificationsDialog(
        currentUser: _currentUser,
        initialNotifications: _notifications,
        onNotificationsUpdated: (notifications, count) {
          setState(() {
            _notifications = notifications;
            _unreadNotifs = count;
          });
        },
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (c) => ProfileDialog(
        currentUser: _currentUser,
        onProfileUpdated: (user) {
          setState(() {
            _currentUser = user;
          });
          _load();
        },
        onLogout: _logout,
      ),
    );
  }

  void _openChatScreen(AgentProfileModel agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(user: _currentUser, agentUserId: agent.userId, agentName: agent.companyName),
      ),
    );
  }

  Future<void> _payBooking(BookingModel b) async {
    await _showPaymentGateway(b);
  }

  Future<void> _showPaymentGateway(BookingModel b) async {
    bool isProcessing = false;
    bool isSuccess = false;
    String statusText = "Connecting to secure gateway...";

    final cardNumController = TextEditingController(text: "4111 2222 3333 4321");
    final nameController = TextEditingController(text: _currentUser.fullName.isEmpty ? _currentUser.username : _currentUser.fullName);
    final expiryController = TextEditingController(text: "12/28");
    final cvvController = TextEditingController(text: "123");

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isSuccess) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0F0F24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF4ECDC4),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Approved!',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Transaction Reference: TXN-${DateTime.now().millisecondsSinceEpoch}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount Paid: RM ${b.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your booking is now confirmed. Safe travels!',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Go to Trips', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (isProcessing) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0F0F24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00D4FF)),
                      const SizedBox(height: 24),
                      Text(
                        statusText,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F0F24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Secure Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Credit Card Preview
                      Container(
                        width: double.infinity,
                        height: 160,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B83FF), Color(0xFF6C63FF), Color(0xFF3F37C9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('💵 Credit Card', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('VISA', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                              ],
                            ),
                            const Text(
                              '🪙',
                              style: TextStyle(fontSize: 22),
                            ),
                            Text(
                              cardNumController.text.isNotEmpty ? cardNumController.text : '**** **** **** ****',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  nameController.text.toUpperCase(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  expiryController.text.isNotEmpty ? expiryController.text : 'MM/YY',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Booking ID: #${b.id} | ${b.destination}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cardNumController,
                        style: const TextStyle(color: Colors.white),
                        decoration: AppTheme.input('Card Number', icon: Icons.credit_card),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: AppTheme.input('Cardholder Name', icon: Icons.person_outline),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              style: const TextStyle(color: Colors.white),
                              decoration: AppTheme.input('Expiry Date'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              style: const TextStyle(color: Colors.white),
                              obscureText: true,
                              decoration: AppTheme.input('CVV'),
                              validator: (v) => v == null || v.length != 3 ? 'Invalid' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() {
                              isProcessing = true;
                              statusText = "Connecting to secure gateway...";
                            });

                            await Future.delayed(const Duration(milliseconds: 600));
                            if (!ctx.mounted) return;
                            setState(() => statusText = "Authorizing transaction...");

                            await Future.delayed(const Duration(milliseconds: 600));
                            if (!ctx.mounted) return;
                            setState(() => statusText = "Processing payment...");

                            await Future.delayed(const Duration(milliseconds: 600));
                            if (!ctx.mounted) return;

                            try {
                              await BookingService.instance.confirmPayment(b.id, _currentUser.id);
                              setState(() {
                                isProcessing = false;
                                isSuccess = true;
                              });
                              _load();
                            } catch (e) {
                              setState(() {
                                isProcessing = false;
                              });
                              showAppSnackBar(context, '$e', isError: true);
                            }
                          },
                          child: Text(
                            'Pay RM ${b.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addReviewDialog(BookingModel b) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Write a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rating:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Center(
                child: StarRating(
                  rating: rating.toDouble(),
                  size: 36,
                  interactive: true,
                  onChanged: (val) {
                    setS(() {
                      rating = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                decoration: AppTheme.input('Comments'),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ReviewService.instance.addReview(
                    userId: _currentUser.id,
                    packageId: b.packageId,
                    agentId: b.agentId,
                    bookingId: b.id,
                    rating: rating,
                    comment: commentCtrl.text.trim(),
                  );
                  Navigator.pop(c);
                  if (mounted) showAppSnackBar(context, 'Review submitted successfully!');
                  _load();
                  if (_selectedPkg != null && _selectedPkg!.id == b.packageId) {
                    final freshReviews = await ReviewService.instance.getReviews(packageId: b.packageId);
                    final freshAvg = await ReviewService.instance.getAverageRating(b.packageId);
                    setState(() {
                      _pkgReviews = freshReviews;
                      _avgRating = freshAvg;
                    });
                  }
                } catch (e) {
                  if (mounted) showAppSnackBar(context, '$e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _bookPackageDialog(TravelPackageModel pkg) {
    final nameCtrl = TextEditingController(text: _currentUser.fullName);
    final icCtrl = TextEditingController(text: _currentUser.icPassport ?? '');
    final peopleCtrl = TextEditingController(text: '1');
    final reqCtrl = TextEditingController();
    final voucherCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    double discount = 0.0;
    VoucherModel? appliedVoucher;
    String? voucherError;
    String? voucherSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final numPeople = int.tryParse(peopleCtrl.text) ?? 1;
          final subtotal = pkg.effectivePrice * numPeople;
          final totalPrice = subtotal - discount;

          Future<void> applyVoucher() async {
            final code = voucherCtrl.text.trim();
            if (code.isEmpty) {
              setDialogState(() {
                appliedVoucher = null;
                discount = 0.0;
                voucherError = null;
                voucherSuccess = null;
              });
              return;
            }

            final v = await VoucherService.instance.getByCode(code);
            if (v == null || v.status != 'active') {
              setDialogState(() {
                appliedVoucher = null;
                discount = 0.0;
                voucherError = "Invalid or expired voucher code";
                voucherSuccess = null;
              });
              return;
            }

            if (subtotal < v.minPurchase) {
              setDialogState(() {
                appliedVoucher = null;
                discount = 0.0;
                voucherError = "Min purchase of RM ${v.minPurchase.toStringAsFixed(2)} required";
                voucherSuccess = null;
              });
              return;
            }

            final now = DateTime.now();
            if (v.validFrom != null && now.isBefore(v.validFrom!)) {
              setDialogState(() {
                appliedVoucher = null;
                discount = 0.0;
                voucherError = "Voucher not valid yet";
                voucherSuccess = null;
              });
              return;
            }
            if (v.validUntil != null && now.isAfter(v.validUntil!)) {
              setDialogState(() {
                appliedVoucher = null;
                discount = 0.0;
                voucherError = "Voucher expired";
                voucherSuccess = null;
              });
              return;
            }

            double computedDiscount = 0.0;
            if (v.discountType == 'percent') {
              computedDiscount = (subtotal * v.discountValue) / 100;
            } else {
              computedDiscount = v.discountValue;
            }

            if (computedDiscount > subtotal) {
              computedDiscount = subtotal;
            }

            setDialogState(() {
              appliedVoucher = v;
              discount = computedDiscount;
              voucherError = null;
              voucherSuccess = "Applied! Saved RM ${computedDiscount.toStringAsFixed(2)}";
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Book Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: AppTheme.input('Full Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: icCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: AppTheme.input('IC / Passport'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: peopleCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.input('Number of People'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = int.tryParse(v);
                        if (val == null || val <= 0) return 'Must be greater than 0';
                        return null;
                      },
                      onChanged: (val) {
                        setDialogState(() {
                          if (appliedVoucher != null) {
                            final newSubtotal = pkg.effectivePrice * (int.tryParse(val) ?? 1);
                            if (newSubtotal < appliedVoucher!.minPurchase) {
                              appliedVoucher = null;
                              discount = 0.0;
                              voucherSuccess = null;
                              voucherError = "Voucher removed: Min purchase not met";
                            } else {
                              if (appliedVoucher!.discountType == 'percent') {
                                discount = (newSubtotal * appliedVoucher!.discountValue) / 100;
                              } else {
                                discount = appliedVoucher!.discountValue;
                              }
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reqCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: AppTheme.input('Special Requirements'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: voucherCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: AppTheme.input('Voucher Code (optional)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4FF),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: applyVoucher,
                          child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (voucherError != null) ...[
                      const SizedBox(height: 4),
                      Text(voucherError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ],
                    if (voucherSuccess != null) ...[
                      const SizedBox(height: 4),
                      Text(voucherSuccess!, style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ],
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        Text('RM ${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                          Text('-RM ${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Price:', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          'RM ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final numPeople = int.tryParse(peopleCtrl.text) ?? 1;
                  try {
                    final bookingId = await BookingService.instance.createBooking(
                      userId: _currentUser.id,
                      packageId: pkg.id,
                      agentId: pkg.agentId,
                      guestName: nameCtrl.text.trim(),
                      icPassport: icCtrl.text.trim(),
                      numPeople: numPeople,
                      travelDate: pkg.travelDate,
                      unitPrice: pkg.effectivePrice,
                      specialRequirements: reqCtrl.text.trim().isEmpty ? null : reqCtrl.text.trim(),
                      voucherCode: appliedVoucher != null ? appliedVoucher!.code : null,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);

                    final booking = await BookingService.instance.getBookingById(bookingId);
                    if (!mounted) return;
                    if (booking != null) {
                      await _showPaymentGateway(booking);
                    } else {
                      showAppSnackBar(context, 'Booking submitted! Complete payment in Trips tab.');
                      _load();
                    }
                  } catch (e) {
                    if (mounted) showAppSnackBar(context, '$e', isError: true);
                  }
                },
                child: const Text('Book Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
