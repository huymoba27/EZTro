import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'widgets/home_header.dart';
import 'widgets/home_drawer.dart';

// Screens
import '../house/list/house_list_screen.dart';
import '../room/list/room_list_screen.dart';
import '../service/list/service_list_screen.dart';
import '../contract/list/contract_list_screen.dart';
import '../tenants/list/tenant_list_screen.dart';
import '../meter/reading/meter_reading_screen.dart';
import '../vehicle/list/vehicle_manage_screen.dart';
import '../invoice/list/invoice_list_screen.dart';
import '../deposit/list/deposit_list_screen.dart';
import '../receipt/list/receipt_list_screen.dart';
import '../receipt/list/expense_list_screen.dart';
import '../statistics/list/statistics_screen.dart';
import '../post/list/post_management_screen.dart';
import '../chat/list/chat_list_screen.dart';
import '../incident/list/manager_incident_list_screen.dart';
import '../notification/list/notification_screen.dart';
import '../ai/ai_assistant_screen.dart';
import 'landlord_more_menu_screen.dart';
import 'tenant_home_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? currentUser;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadNotificationCountProvider.notifier).refresh();
    });
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) setState(() => currentUser = user);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn thoát tài khoản?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const TenantHomeScreen()),
        (route) => false,
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
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: HomeDrawer(user: currentUser, onLogout: _handleLogout),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiAssistantScreen(),
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                )
              : null,
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const StatisticsScreen();
      case 2:
        return ChatListScreen(onBack: () => setState(() => _currentIndex = 0));
      case 3:
        return ManagerIncidentListScreen(
          onBackToHome: () => setState(() => _currentIndex = 0),
        );
      case 4:
        return LandlordMoreMenuScreen(
          user: currentUser,
          onLogout: _handleLogout,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          HomeHeader(
            user: currentUser,
            onNotificationTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuSection("QUẢN LÝ VẬN HÀNH", [
            const AppMenuItem(
              icon: Icons.home_rounded,
              label: "Khu trọ",
              color: AppColors.primary,
              nextScreen: HouseListScreen(),
            ),
            const AppMenuItem(
              icon: Icons.meeting_room_rounded,
              label: "Phòng",
              color: Colors.orange,
              nextScreen: RoomListScreen(houseId: 0, houseName: "Tất cả"),
            ),
            const AppMenuItem(
              icon: Icons.cleaning_services_rounded,
              label: "Dịch vụ",
              color: Colors.purple,
              nextScreen: ServiceListScreen(houseId: 0, houseName: "Tất cả"),
            ),
            const AppMenuItem(
              icon: Icons.assignment_rounded,
              label: "Hợp đồng",
              color: Colors.indigo,
              nextScreen: ContractListScreen(),
            ),
          ]),
          _buildMenuSection("TÀI CHÍNH & KHÁCH HÀNG", [
            const AppMenuItem(
              icon: Icons.water_drop_rounded,
              label: "Điện nước",
              color: Colors.teal,
              nextScreen: MeterReadingScreen(),
            ),
            const AppMenuItem(
              icon: Icons.receipt_long_rounded,
              label: "Hóa đơn",
              color: Colors.redAccent,
              nextScreen: InvoiceListScreen(),
            ),
            const AppMenuItem(
              icon: Icons.price_check_rounded,
              label: "Cọc giữ chỗ",
              color: Colors.pink,
              nextScreen: DepositListScreen(),
            ),
            const AppMenuItem(
              icon: Icons.people_alt_rounded,
              label: "Khách thuê",
              color: Colors.blue,
              nextScreen: TenantListScreen(),
            ),
          ]),
          _buildMenuSection("TIỆN ÍCH KHÁC", [
            const AppMenuItem(
              icon: Icons.account_balance_wallet_rounded,
              label: "Phiếu thu",
              color: Colors.green,
              nextScreen: ReceiptListScreen(),
            ),
            const AppMenuItem(
              icon: Icons.payments_rounded,
              label: "Phiếu chi",
              color: Colors.orangeAccent,
              nextScreen: ExpenseListScreen(),
            ),
            const AppMenuItem(
              icon: Icons.two_wheeler_rounded,
              label: "Quản lý xe",
              color: Colors.brown,
              nextScreen: VehicleManageScreen(),
            ),
            const AppMenuItem(
              icon: Icons.campaign_rounded,
              label: "Tin đăng",
              color: Colors.teal,
              nextScreen: PostManagementScreen(),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.grey[700],
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: items,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(26), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[400],
        onTap: (index) => setState(() => _currentIndex = index),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'TRANG CHỦ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'THỐNG KÊ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'TIN NHẮN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            label: 'SỰ CỐ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'THÊM',
          ),
        ],
      ),
    );
  }
}
