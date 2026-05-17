import 'package:eztro/core/utils/format_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../invoice/detail/invoice_detail_screen.dart';
import '../../contract/detail/contract_detail_screen.dart';
import '../../deposit/detail/deposit_detail_screen.dart';
import '../../../models/contract_model.dart';
import '../../incident/detail/incident_detail_screen.dart';

import '../../meter/reading/meter_reading_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/notification_provider.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../home/home_screen.dart';
import '../../home/tenant_home_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int _selectedTabIndex = 0;
  UserModel? currentUser;
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  final List<String> _tabs = [
    "Tất cả",
    "Hợp đồng",
    "Thanh toán",
    "Sự cố",
    "Hệ thống",
  ];
  final List<String> _tabFilters = [
    "all",
    "contract",
    "payment",
    "incident",
    "system",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => currentUser = user);
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);

    final results = await NotificationService.getNotifications(
      userId: currentUser!.id,
      filter: _tabFilters[_selectedTabIndex],
    );

    if (mounted) {
      setState(() {
        _notifications = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _onMarkAsRead(NotificationModel item) async {
    // 1. Đánh dấu đã đọc trên server
    if (!item.isRead) {
      final success = await NotificationService.markAsRead(
        userId: currentUser!.id,
        notificationId: item.id,
      );
      if (success && mounted) {
        setState(() => item.isRead = true);
        // Cập nhật số lượng thông báo chưa đọc toàn cục
        ref.read(unreadNotificationCountProvider.notifier).decrement();
      }
    }

    // 2. Điều hướng dựa trên loại thông báo
    if (!mounted) return;

    final metadata = item.metadata;
    final type = item.type;

    if (type == NotificationType.invoice && metadata?['invoice_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(
            invoiceId: int.parse(metadata!['invoice_id'].toString()),
          ),
        ),
      );
    } else if (type == NotificationType.contract &&
        metadata?['contract_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContractDetailScreen(
            contract: ContractModel(
              id: int.parse(metadata!['contract_id'].toString()),
              roomId: 0,
              roomName: 'N/A',
              startDate: '',
              endDate: '',
              rentPrice: 0,
              depositAmount: 0,
              paymentDay: 0,
              startElectric: 0,
              startWater: 0,
              status: 'active',
            ),
          ),
        ),
      );
    } else if (type == NotificationType.payment &&
        metadata?['deposit_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositDetailScreen(
            depositId: int.parse(metadata!['deposit_id'].toString()),
          ),
        ),
      );
    } else if (type == "incident" && metadata?['incident_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(
            incidentId: int.parse(metadata!['incident_id'].toString()),
          ),
        ),
      );
    } else if (type == NotificationType.utility) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MeterReadingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: _notifications.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: _buildEmptyState(),
                              ),
                            )
                          : _buildNotificationList(),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    if (currentUser == null) return const SizedBox();
    bool isLandlord = currentUser!.role == 'landlord';

    final items = isLandlord
        ? [
            {'icon': Icons.home_rounded, 'label': 'TRANG CHỦ'},
            {'icon': Icons.bar_chart_rounded, 'label': 'THỐNG KÊ'},
            {'icon': Icons.chat_bubble_outline_rounded, 'label': 'TIN NHẮN'},
            {'icon': Icons.report_problem_outlined, 'label': 'SỰ CỐ'},
            {'icon': Icons.grid_view_rounded, 'label': 'THÊM'},
          ]
        : [
            {'icon': Icons.search_rounded, 'label': 'TÌM CHỖ Ở'},
            {'icon': Icons.receipt_long_rounded, 'label': 'HÓA ĐƠN'},
            {'icon': Icons.chat_bubble_outline_rounded, 'label': 'HỘP THƯ'},
            {'icon': Icons.grid_view_rounded, 'label': 'THÊM'},
          ];

    return Container(
      height: 60 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(26), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: InkWell(
              onTap: () {
                if (isLandlord) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(initialIndex: index),
                    ),
                    (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantHomeScreen(initialIndex: index),
                    ),
                    (route) => false,
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    int unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      padding: EdgeInsets.fromLTRB(10, statusBarHeight + 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Lottie.asset(
                        "assets/lottie/welcome_bird.json",
                        repeat: true,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    currentUser?.fullName ?? "Người dùng",
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "BẠN CÓ $unreadCount THÔNG BÁO MỚI",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          bool isActive = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTabIndex = index);
              _fetchNotifications();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : Colors.grey.withAlpha(51),
                  width: 1,
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black54,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return GestureDetector(
          onTap: () => _onMarkAsRead(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: item.isRead
                  ? null
                  : Border.all(color: item.color.withAlpha(77), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    if (!item.isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title
                                  .replaceAll('(Hệ thống)', '')
                                  .replaceAll('Hệ thống:', '')
                                  .trim(),
                              style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(item.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isRead ? Colors.black54 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays == 1) return "Hôm qua";
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: "Chưa có thông báo nào",
              subtitle: "Chúng tôi sẽ báo cho bạn khi có tin mới!",
            ),
          ),
        );
      },
    );
  }
}
