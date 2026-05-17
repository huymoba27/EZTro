import 'dart:async';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/notification_provider.dart';
import '../../core/utils/format_helper.dart';
import '../../services/auth_service.dart';
import '../invoice/list/invoice_list_screen.dart';
import '../auth/login_screen.dart';
import '../../models/post_model.dart';
import 'post_detail_screen.dart';
import '../../services/post_service.dart';
import '../../services/api_constants.dart';
import '../chat/list/chat_list_screen.dart';
import '../search/list/public_post_list_screen.dart';
import '../deposit/list/tenant_deposit_list_screen.dart';
import '../../models/user_model.dart';
import '../favorite/list/favorite_list_screen.dart';
import '../incident/report/incident_report_screen.dart';
import '../shipping/list/shipping_screen.dart';
import '../notification/list/notification_screen.dart';
import '../ai/tenant_ai_chat_screen.dart';
import 'tenant_more_menu_screen.dart';

class TenantHomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const TenantHomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends ConsumerState<TenantHomeScreen> {
  late int _currentIndex;
  late Future<List<PostModel>> _postsFuture;
  late Future<List<PostModel>> _bestRoomsFuture;
  late Future<List<PostModel>> _immediateRoomsFuture;
  UserModel? _currentUser;

  // Slogan Animation
  int _sloganIndex = 0;
  late Timer _sloganTimer;
  final List<String> _slogans = [
    "Chỗ như ý, giá hợp lý!",
    "Xem ngay tại EZTro.",
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _postsFuture = PostService.getPosts();
    _bestRoomsFuture = _fetchShuffledPosts();
    _immediateRoomsFuture = _fetchShuffledPosts();
    _loadUser();

    // Start slogan timer
    _sloganTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _sloganIndex = (_sloganIndex + 1) % _slogans.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadNotificationCountProvider.notifier).refresh();
    });
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _postsFuture = PostService.getPosts();
      _bestRoomsFuture = _fetchShuffledPosts();
      _immediateRoomsFuture = _fetchShuffledPosts();
    });
    await Future.wait([
      _postsFuture,
      _bestRoomsFuture,
      _immediateRoomsFuture,
      _loadUser(),
      ref.read(unreadNotificationCountProvider.notifier).refresh(),
    ]);
  }

  Future<List<PostModel>> _fetchShuffledPosts() async {
    final posts = await PostService.getPosts();
    posts.shuffle();
    return posts;
  }

  void _checkLoginAndNavigate(Widget screen) {
    if (_currentUser == null) {
      _showLoginRequiredDialog();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: const Text("Bạn cần đăng nhập để sử dụng tính năng này."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BỎ QUA", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text(
              "ĐĂNG NHẬP",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sloganTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () async {
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: _buildBody(),
          floatingActionButton: null,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withAlpha(26), width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if ((index == 1 || index == 2) && _currentUser == null) {
                  _showLoginRequiredDialog();
                  return;
                }
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF2E7D32),
              unselectedItemColor: Colors.grey[400],
              showUnselectedLabels: true,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: "TÌM CHỖ Ở",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: "HÓA ĐƠN",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: "HỘP THƯ",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: "THÊM",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _currentUser != null
            ? InvoiceListScreen(onBack: () => setState(() => _currentIndex = 0))
            : const SizedBox();
      case 2:
        return _currentUser != null
            ? ChatListScreen(onBack: () => setState(() => _currentIndex = 0))
            : const SizedBox();
      case 3:
        return TenantMoreMenuScreen(
          user: _currentUser,
          onLogout: () async {
            await AuthService.logout();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const TenantHomeScreen(),
                ),
                (route) => false,
              );
            }
          },
        );
      default:
        return const Center(child: Text("Đang phát triển..."));
    }
  }

  Widget _buildHomeContent() {
    return FutureBuilder<List<PostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFullPageSkeleton();
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF2E7D32),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildTopSection()),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildMenuSection(),
                    _buildDivider(),
                    _buildSectionHeader(
                      "Phòng đẹp giá tốt",
                      "Dẫn xem tận nơi!",
                    ),
                    const SizedBox(height: 12),
                    _buildHorizontalListing(_bestRoomsFuture),
                    _buildDivider(),
                    _buildBannerSection(),

                    const SizedBox(height: 12),
                    _buildHorizontalListing(_immediateRoomsFuture),
                    _buildDivider(),
                    _buildSectionHeader(
                      "Trọ mới đăng",
                      "Vừa cập nhật",
                      isOrange: true,
                    ),
                    const SizedBox(height: 12),
                    _buildVerticalListing(_postsFuture),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullPageSkeleton() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate menu spacing like in real widget
    double availableWidth = screenWidth - 40;
    double iconSize = 60;
    double menuSpacing = (availableWidth - (iconSize * 4)) / 3;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-style Header (Empty)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120 + statusBarHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(8, statusBarHeight + 4, 16, 0),
              ),
              // Search Bar Overlap Skeleton
              Positioned(
                bottom: -25,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 55),
          // Body Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu Grid (8 items, Rounded Squares)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Wrap(
                    spacing: menuSpacing,
                    runSpacing: 40, // Balanced spacing
                    children: List.generate(
                      8,
                      (index) => SizedBox(
                        width: iconSize,
                        child: Column(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 50,
                              height: 8,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Divider
                Container(
                  height: 6,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 15),
                // Section Header (Merged into 1 line as requested)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 150, height: 14, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Listing Skeletons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(
                      2,
                      (index) => Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 140,
                              width: 220,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Two-line Title Skeleton (Attached closer)
                            Container(
                              height: 10,
                              width: 200,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 10,
                              width: 140,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 22),
                            // Price & Area Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 12,
                                  width: 70,
                                  color: Colors.white,
                                ),
                                Container(
                                  height: 12,
                                  width: 40,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120 + statusBarHeight,
          padding: EdgeInsets.fromLTRB(10.0, statusBarHeight + 12, 16.0, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.asset(
                    "assets/lottie/welcome_bird.json",
                    width: 70,
                    height: 70,
                    repeat: true,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Xin chào, ",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                StringHelper.capitalizeEachWord(
                                  _currentUser?.fullName ?? "Quý khách",
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          switchInCurve: const Interval(
                            0.5,
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                          switchOutCurve: const Interval(
                            0.0,
                            0.5,
                            curve: Curves.easeInCubic,
                          ),
                          layoutBuilder:
                              (
                                Widget? currentChild,
                                List<Widget> previousChildren,
                              ) {
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: <Widget>[
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                final isEntering =
                                    child.key == ValueKey<int>(_sloganIndex);

                                if (isEntering) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.5),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                } else {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                }
                              },
                          child: Text(
                            _slogans[_sloganIndex],
                            key: ValueKey<int>(_sloganIndex),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderButton(Icons.favorite_border, () {
                        _checkLoginAndNavigate(const FavoriteListScreen());
                      }),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        Icons.notifications_none,
                        () async {
                          _checkLoginAndNavigate(const NotificationScreen());
                          // Refresh count when coming back
                        },
                        badgeCount: ref.watch(unreadNotificationCountProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -25,
          left: 0,
          right: 0,
          child: _buildSearchBarSection(),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badgeCount > 9 ? "9+" : "$badgeCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBarSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PublicPostListScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.black54),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Thuê trên",
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    Text(
                      "Toàn quốc",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              height: 30,
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.black54),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Gần trường, công ty, chợ...",
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              radius: 16,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSpace() {
    return const SizedBox(height: 40);
  }

  Widget _buildMenuSection() {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.map,
        'label': 'Trọ gần tôi',
        'color': Colors.amber,
        'badge': true,
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Trợ lý \nAI',
        'color': Colors.blue,
      },
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Đặt cọc phòng',
        'color': Colors.purple,
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Vận chuyển',
        'color': Colors.teal,
      },
      if (_currentUser?.isRenting == true)
        {
          'icon': Icons.receipt_long,
          'label': 'Hóa đơn tháng',
          'color': Colors.red,
        },
      if (_currentUser?.isRenting == true)
        {
          'icon': Icons.report_problem_outlined,
          'label': 'Báo cáo sự cố',
          'color': Colors.orange,
        },
    ];

    double availableWidth = MediaQuery.of(context).size.width - 40;
    double iconSize = 60;
    double spacing = (availableWidth - (iconSize * 4)) / 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      color: Colors.white,
      child: Wrap(
        spacing: spacing,
        runSpacing: 20,
        children: menuItems.map((item) {
          return SizedBox(
            width: iconSize,
            child: GestureDetector(
              onTap: () {
                if (item['label'] == 'Hóa đơn tháng') {
                  _checkLoginAndNavigate(const InvoiceListScreen());
                } else if (item['label'] == 'Trọ gần tôi') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PublicPostListScreen(),
                    ),
                  );
                } else if (item['label'] == 'Đặt cọc phòng') {
                  _checkLoginAndNavigate(const TenantDepositListScreen());
                } else if (item['label'] == 'Báo cáo sự cố') {
                  _checkLoginAndNavigate(const IncidentReportScreen());
                } else if (item['label'] == 'Trợ lý \nAI') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TenantAiChatScreen(),
                    ),
                  );
                } else if (item['label'] == 'Vận chuyển') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShippingScreen()),
                  );
                }
              },
              child: _buildMenuItem(
                item['icon'],
                item['label'],
                item['color'],
                hasBadge: item['badge'] ?? false,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    Color color, {
    bool hasBadge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            if (hasBadge)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    bool isOrange = false,
  }) {
    Color mainColor = isOrange ? Colors.orange[800]! : const Color(0xFF2E7D32);
    Color bgColor = isOrange
        ? Colors.orange.withOpacity(0.05)
        : Colors.green.withOpacity(0.05);
    IconData iconData = Icons.fiber_new_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, color: mainColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalListing(Future<List<PostModel>> future) {
    return SizedBox(
      height: 250,
      child: FutureBuilder<List<PostModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // No individual skeleton needed if full page skeleton is showing
            return const SizedBox();
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text("Cùng đón chờ các phòng mới nhé!"));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildListingCard(posts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 12, width: 180, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 10, width: 120, color: Colors.white),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12, width: 80, color: Colors.white),
                  Container(height: 12, width: 50, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(PostModel post, {double? width}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: post.id ?? 0),
          ),
        );
      },
      child: Container(
        width: width ?? 220,
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: width != null ? 120 : 140,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: post.images != null && post.images!.isNotEmpty
                          ? Image.network(
                              "${ApiConstants.baseUrl}/uploads/rooms/${post.images}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "HOT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Content Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${_cleanAddressPart(post.ward)} . ${_cleanAddressPart(post.city)}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 0.5),
                            child: const Icon(
                              Icons.paid_outlined,
                              color: Colors.red,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatPriceString(
                              post.priceDisplay ?? post.originalPrice,
                            ),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1.5),
                            child: const Icon(
                              Icons.aspect_ratio,
                              color: Colors.black54,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${post.area} m2",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: const Color(0xFFE0F7FA), // Light cyan base color
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF006064), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Thuê ở ngay - NOW",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF006064),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Phòng bạn có thể thuê ngay từ hôm nay",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalListing(Future<List<PostModel>> future) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<PostModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) return const SizedBox();

          // Limit to 10 items
          final displayPosts = posts.take(10).toList();
          final double cardWidth =
              (MediaQuery.of(context).size.width - 32 - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: displayPosts.map((post) {
              return _buildListingCard(post, width: cardWidth);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildVerticalSkeleton() {
    final double cardWidth = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: List.generate(
        4,
        (index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: SizedBox(
            width: cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 10,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(height: 8, width: 100, color: Colors.white),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 10, width: 60, color: Colors.white),
                    Container(height: 10, width: 40, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 6,
      width: double.infinity,
      color: Colors.grey[200],
    );
  }

  String _cleanAddressPart(String? part) {
    if (part == null) return '';
    return part
        .replaceAll(
          RegExp(
            r'Phường |Quận |Thành phố |Tỉnh |Thị xã |Huyện ',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String _formatPriceString(String? priceStr) {
    if (priceStr == null || priceStr.isEmpty) return '0 đ';

    // Sử dụng Regex để tìm phần thập phân ở cuối chuỗi (ví dụ .00 hoặc ,00 hoặc .5)
    // Nếu tìm thấy một dấu ngăn cách theo sau bởi 1 hoặc 2 chữ số ở cuối, ta loại bỏ nó.
    String cleanStr = priceStr.replaceFirst(RegExp(r'[.,]\d{1,2}$'), '');

    // Loại bỏ tất cả ký tự không phải số còn lại (dấu chấm hàng nghìn...)
    String cleanDigits = cleanStr.replaceAll(RegExp(r'[^0-9]'), '');
    int value = int.tryParse(cleanDigits) ?? 0;
    return CurrencyHelper.formatVND(value);
  }
}
