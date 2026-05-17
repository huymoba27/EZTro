import 'package:flutter/material.dart';
import '../../core/utils/format_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/deposit_service.dart';
import '../chat/detail/chat_detail_screen.dart';
import '../deposit/detail/tenant_deposit_qr_screen.dart';
import '../auth/login_screen.dart';
import '../../services/favorite_service.dart';
import 'post_location_screen.dart';
import '../../core/utils/dialog_helper.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _post;
  bool _isLoading = true;
  bool _isFavorited = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final user = await AuthService.getCurrentUser();
      final post = await PostService.getPostDetail(
        widget.postId,
        userId: user?.id,
      );
      if (mounted) {
        setState(() {
          _post = post;
          _isFavorited = post?.isFavorited ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    final result = await FavoriteService.toggleFavorite(
      userId: user.id,
      postId: widget.postId,
    );

    if (result['status'] == 'success') {
      setState(() {
        _isFavorited = result['action'] == 'added';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chi tiết")),
        body: const Center(child: Text("Không tìm thấy thông tin tin đăng.")),
      );
    }

    final post = _post!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(post),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildMainInfo(post),
                  const SizedBox(height: 10),
                  _buildOwnerSection(post),
                  const Divider(
                    height: 32,
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildRoomFeatures(post),
                  const Divider(
                    height: 32,
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildDescriptionSection(post),
                  const Divider(
                    height: 32,
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildAmenitiesSection(post),
                  const Divider(
                    height: 32,
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildMapSection(post),
                  const Divider(
                    height: 32,
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildNotesSection(post),
                  const SizedBox(height: 80), // Space for bottom bar
                ]),
              ),
            ],
          ),
          _buildBottomBar(post),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(PostModel post) {
    final List<String> images = post.allImages ?? [];
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          FlexibleSpaceBar(
            background: Stack(
              alignment: Alignment.bottomRight,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentImageIndex = index),
                  itemCount: images.isEmpty ? 1 : images.length,
                  itemBuilder: (context, index) {
                    if (images.isEmpty) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    }
                    return Image.network(
                      "${ApiConstants.baseUrl}/uploads/rooms/${images[index]}",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    );
                  },
                ),
                if (images.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${_currentImageIndex + 1}/${images.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo(PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  [
                    if (post.addressDetail != null &&
                        post.addressDetail!.isNotEmpty)
                      post.addressDetail,
                    if (post.ward != null && post.ward!.isNotEmpty) post.ward,
                    if (post.city != null && post.city!.isNotEmpty) post.city,
                  ].join(', '),
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFeatures(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Đặc điểm phòng"),
          const SizedBox(height: 12),
          // Khối 1: Tài chính & Diện tích
          _buildFeatureBlock([
            _buildFeatureItem(
              Icons.monetization_on_outlined,
              "Giá thuê",
              CurrencyHelper.formatVND(
                post.originalPrice,
              ).replaceAll("đ", "").trim(),
              valueColor: Colors.red,
            ),
            _buildFeatureItem(
              Icons.aspect_ratio,
              "Diện tích",
              "${post.area ?? '0'} m2",
            ),
            _buildFeatureItem(
              Icons.account_balance_wallet_outlined,
              "Tiền cọc",
              post.deposit != null
                  ? CurrencyHelper.formatVND(post.deposit)
                  : _getServicePrice(post, "Cọc", isRaw: true),
            ),
          ]),
          const SizedBox(height: 10),
          // Khối 2: Dịch vụ & Công suất
          _buildFeatureBlock([
            _buildFeatureItem(
              Icons.wb_sunny_outlined,
              "Tiền điện",
              _getServicePrice(post, "Điện", isRaw: true),
            ),
            _buildFeatureItem(
              Icons.opacity,
              "Tiền nước",
              _getServicePrice(post, "Nước", isRaw: true),
            ),
            _buildFeatureItem(
              Icons.people_outline,
              "Số người ở",
              post.maxTenants != null
                  ? "${post.maxTenants} người"
                  : "Chưa xác định",
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeatureBlock(List<Widget> items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: items.map((item) => Expanded(child: item)).toList()),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: Colors.black54),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getServicePrice(PostModel post, String name, {bool isRaw = false}) {
    // Ưu tiên lấy từ các trường đã được "làm giàu" (Enriched) từ API mới
    if (name.toLowerCase().contains("điện") && post.electricPrice != null) {
      if (isRaw) return CurrencyHelper.formatVND(post.electricPrice);
      return "${CurrencyHelper.formatVND(post.electricPrice)}/kWh";
    }
    if (name.toLowerCase().contains("nước") && post.waterPrice != null) {
      if (isRaw) return CurrencyHelper.formatVND(post.waterPrice);
      return "${CurrencyHelper.formatVND(post.waterPrice)}/m3";
    }

    // Fallback cho các dịch vụ khác hoặc dữ liệu cũ
    if (post.services == null) return "N/A";
    final svc = post.services!.firstWhere(
      (s) => s['service_name'].toString().toLowerCase().contains(
        name.toLowerCase(),
      ),
      orElse: () => null,
    );
    if (svc == null) return "N/A";
    final price = double.tryParse(svc['price'].toString()) ?? 0;
    if (isRaw) return CurrencyHelper.formatVND(price);
    return "${CurrencyHelper.formatVND(price)}/${svc['unit']}";
  }

  Widget _buildOwnerSection(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.contactName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  "Chủ trọ / Quản lý",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(post.contactPhone),
            icon: const Icon(Icons.phone, color: Colors.blue),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message, color: Colors.orange),
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Mô tả bài đăng"),
          const SizedBox(height: 12),
          Text(
            post.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(PostModel post) {
    final List<String> amenities = post.amenities ?? [];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Tiện ích"),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: amenities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 45,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black87.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    _getAmenityIcon(amenities[index]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        amenities[index],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getAmenityIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('wifi')) {
      return const Icon(Icons.wifi, size: 18, color: Colors.black87);
    }
    if (name.contains('xe')) {
      return const Icon(Icons.directions_car, size: 18, color: Colors.black87);
    }
    if (name.contains('thú cưng') ||
        name.contains('chó') ||
        name.contains('mèo')) {
      return const Icon(Icons.pets, size: 18, color: Colors.black87);
    }
    if (name.contains('chủ')) {
      return const Icon(Icons.vpn_key, size: 18, color: Colors.black87);
    }
    if (name.contains('camera')) {
      return const Icon(Icons.security, size: 18, color: Colors.black87);
    }
    if (name.contains('ban công')) {
      return const Icon(Icons.balcony, size: 18, color: Colors.black87);
    }
    if (name.contains('sinh hoạt')) {
      return const Icon(Icons.diversity_3, size: 18, color: Colors.black87);
    }
    return const Icon(
      Icons.check_circle_outline,
      size: 18,
      color: Colors.black87,
    );
  }

  Widget _buildNotesSection(PostModel post) {
    final rulesStr = post.houseRules?.trim() ?? "";
    if (rulesStr.isEmpty) return const SizedBox.shrink();

    // Tách các dòng theo dấu xuống dòng hoặc dấu chấm phẩy
    final rules = rulesStr
        .split(RegExp(r'[\n;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Nội quy nhà"),
          const SizedBox(height: 12),
          ...rules.asMap().entries.map((entry) {
            int idx = entry.key + 1;
            String text = entry.value;
            // Loại bỏ số thứ tự cũ nếu người dùng đã tự nhập (ví dụ "1. Nội quy" -> "Nội quy")
            text = text.replaceFirst(RegExp(r'^\d+[\.\-\s)]+'), '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$idx. ",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.8,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapSection(PostModel post) {
    if (post.latitude == null || post.longitude == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Vị trí"),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: MapWidget(
                      cameraOptions: CameraOptions(
                        center: Point(
                          coordinates: Position(
                            post.longitude!,
                            post.latitude!,
                          ),
                        ),
                        zoom: 14,
                      ),
                      onMapCreated: (mapboxMap) async {
                        await mapboxMap.scaleBar.updateSettings(
                          ScaleBarSettings(enabled: false),
                        );
                        await mapboxMap.attribution.updateSettings(
                          AttributionSettings(enabled: false),
                        );
                        await mapboxMap.logo.updateSettings(
                          LogoSettings(enabled: false),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostLocationScreen(
                                latitude: post.latitude!,
                                longitude: post.longitude!,
                                address: [
                                  if (post.addressDetail != null &&
                                      post.addressDetail!.isNotEmpty)
                                    post.addressDetail,
                                  if (post.ward != null &&
                                      post.ward!.isNotEmpty)
                                    post.ward,
                                  if (post.city != null &&
                                      post.city!.isNotEmpty)
                                    post.city,
                                ].join(', '),
                                title: post.title,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Static Pin Overlay
                  const IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_pin, color: Colors.red, size: 40),
                          SizedBox(height: 28), // Small offset for pin tip
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PostModel post) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomBtn(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    "Lưu",
                    _toggleFavorite,
                    color: _isFavorited ? Colors.red : Colors.black87,
                  ),
                  _buildBottomBtn(
                    Icons.chat_bubble_outline,
                    "Chat",
                    () => _handleChat(post),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handleDeposit(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "ĐẶT CỌC NGAY",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChat(PostModel post) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }
    if (post.contactUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chủ trọ chưa cấu hình thông tin chat")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          receiverId: post.contactUserId!,
          receiverName: post.contactName,
          postId: post.id,
        ),
      ),
    );
  }

  Future<void> _handleDeposit(PostModel post) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    // Confirm dialog
    DialogHelper.showCustomConfirm(
      context: context,
      title: "XÁC NHẬN ĐẶT CỌC",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Phòng: ${post.roomName ?? 'N/A'}",
            style: const TextStyle(fontSize: 14, height: 1.8),
          ),
          const SizedBox(height: 10),
          Text(
            "Nhà: ${post.houseName ?? 'N/A'}",
            style: const TextStyle(fontSize: 14, height: 1.8),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Bạn có 5 phút để hoàn tất thanh toán qua QR code sau khi nhấn xác nhận.",
                    style: TextStyle(fontSize: 13, color: Colors.orange, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onConfirm: () => _executeDeposit(post),
    );
  }

  Future<void> _executeDeposit(PostModel post) async {
    final user = await AuthService.getCurrentUser();
    if (user == null || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );

    // Gọi API tạo đặt cọc
    final result = await DepositService.createTenantDeposit(
      userId: user.id,
      roomId: post.roomId,
      houseId: post.houseId ?? 0,
      customerName: user.fullName,
      customerPhone: user.phoneNumber ?? user.username,
      postId: post.id,
    );

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (result['status'] == 'success') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TenantDepositQrScreen(
            depositId: result['deposit_id'],
            checkoutUrl: result['checkout_url'],
            qrCode: result['qr_code'],
            expiresAt: result['expires_at'] ?? '',
            amount: result['amount'] ?? 0,
            roomName: result['room_name'] ?? post.roomName ?? 'N/A',
            houseName: result['house_name'] ?? post.houseName ?? 'N/A',
            bankBin: result['bank_bin'],
            bankAccountNumber: result['bank_account_number'],
            bankAccountName: result['bank_account_name'],
            paymentDescription: result['payment_description'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Lỗi tạo đơn cọc'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginRequiredDialog() {
    DialogHelper.showLoginRequired(
      context: context,
      onLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
    );
  }

  Widget _buildBottomBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color ?? Colors.black87),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
