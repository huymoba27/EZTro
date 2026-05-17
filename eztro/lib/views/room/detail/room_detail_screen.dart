import 'package:eztro/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eztro/core/utils/format_helper.dart';
import 'package:eztro/services/api_constants.dart';
import 'package:eztro/core/utils/dialog_helper.dart';
import 'package:eztro/views/room/create/create_room_screen.dart';
import 'package:eztro/views/contract/detail/widgets/contract_detail_widget.dart';
import 'package:eztro/views/contract/create/create_contract_screen.dart';
import 'package:eztro/views/tenants/list/tenant_list_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eztro/models/tenant_model.dart';
import 'package:eztro/views/room/providers/room_notifier.dart';
import 'package:eztro/views/house/providers/house_notifier.dart';
import 'package:eztro/core/constants/app_colors.dart';
import 'package:eztro/models/contract_model.dart';
import 'package:eztro/models/room_model.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final int roomId;
  final int houseId;
  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.houseId,
  });

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isLoading = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
  }

  void _deleteRoomConfirm(Map<String, dynamic> room) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "Xác nhận xóa",
      message:
          "Bạn có chắc muốn xóa phòng này? Mọi dữ liệu liên quan sẽ bị mất.",
      onConfirm: () async {
        setState(() => _isLoading = true);
        var result = await ref
            .read(roomNotifierProvider(houseId: widget.houseId).notifier)
            .deleteRoom(widget.roomId, houseId: widget.houseId);

        if (result['status'] == 'success') {
          if (!mounted) return;
          DialogHelper.showSuccess(
            context,
            "Đã xóa phòng thành công!",
            onTap: () {
              // Cập nhật số lượng phòng ở danh sách nhà
              ref.read(houseNotifierProvider.notifier).refresh();
              Navigator.pop(context, true); // Back to list
            },
          );
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            DialogHelper.showError(
              context,
              result['message'] ?? "Không thể xóa phòng này.",
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerKey = "${widget.roomId}_${widget.houseId}";
    final roomAsync = ref.watch(roomDetailProvider(providerKey));

    // Nếu đang load lần đầu (không có dữ liệu cũ)
    if (roomAsync.isLoading && !roomAsync.hasValue) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: CustomAppBar(
          title: "CHI TIẾT PHÒNG",
          onBack: () => Navigator.pop(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Nếu lỗi
    if (roomAsync.hasError && !roomAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text("LỖI")),
        body: Center(
          child: Text("Không thể tải thông tin phòng: ${roomAsync.error}"),
        ),
      );
    }

    // Lấy dữ liệu (nếu đang refresh thì vẫn có dữ liệu cũ)
    final roomMap = roomAsync.value ?? {};

        final List<TenantModel> tenantsList =
            (roomMap['tenants_list'] as List? ?? [])
                .map((item) => TenantModel.fromJson(item))
                .toList();

        return DefaultTabController(
          length: 3,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              Navigator.pop(context, _hasChanged);
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF2F2F7),
              appBar: CustomAppBar(
                title: "CHI TIẾT PHÒNG",
                onBack: () => Navigator.pop(context, _hasChanged),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => _showOptionsBottomSheet(context, roomMap),
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: "THÔNG TIN"),
                    Tab(text: "KHÁCH THUÊ"),
                    Tab(text: "HỢP ĐỒNG"),
                  ],
                ),
              ),
              body: Stack(
                children: [
                  TabBarView(
                    children: [
                      _buildInfoTab(roomMap),
                      Container(
                        decoration: const BoxDecoration(color: Colors.white),
                        child: TenantListBody(
                          tenants: tenantsList,
                          isLoading: _isLoading,
                          onRefresh: () => ref.refresh(
                            roomDetailProvider(
                              "${widget.roomId}_${widget.houseId}",
                            ).future,
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        child: roomMap['contract_id'] != null
                            ? ContractDetailWidget(
                                contract: ContractModel.fromJson(roomMap),
                                onUpdate: () => ref.refresh(
                                  roomDetailProvider(
                                    "${widget.roomId}_${widget.houseId}",
                                  ).future,
                                ),
                              )
                            : Center(
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const EmptyStateWidget(
                                        icon: Icons.description_outlined,
                                        title: "Phòng chưa có hợp đồng",
                                        subtitle:
                                            "Bắt đầu tạo hợp đồng mới cho khách thuê tại đây",
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: 220,
                                        child: PrimaryButton(
                                          label: "TẠO HỢP ĐỒNG MỚI",
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CreateContractScreen(
                                                  roomData:
                                                      RoomModel.fromJson(roomMap),
                                                ),
                                              ),
                                            );
                                            if (result == true) {
                                              ref.refresh(
                                                roomDetailProvider(
                                                  "${widget.roomId}_${widget.houseId}",
                                                ).future,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildInfoTab(Map<String, dynamic> room) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(
        roomDetailProvider("${widget.roomId}_${widget.houseId}").future,
      ),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(room),
            _buildMainInfoSection(room),
            _buildDivider(),
            _buildDetailedInfoSection(room),
            _buildDivider(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(Map<String, dynamic> room) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(color: Colors.white),
      child: _buildRoomImage(room),
    );
  }

  Widget _buildMainInfoSection(Map<String, dynamic> room) {
    return AppSectionCard(
      title: "THÔNG TIN PHÒNG",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.meeting_room_outlined,
            label: "Tên phòng",
            value: room['room_name'] ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.business_rounded,
            label: "Thuộc nhà",
            value: room['house_name'] ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.info_outline,
            label: "Trạng thái",
            value: "",
            customValueWidget: Align(
              alignment: Alignment.centerRight,
              child: AppStatusBadge(
                status: room['status']?.toString() ?? "empty",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoSection(Map<String, dynamic> room) {
    return AppSectionCard(
      title: "THÔNG TIN CHI TIẾT",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.monetization_on_outlined,
            label: "Giá thuê",
            value: CurrencyHelper.formatVND(room['price']),
            customValueWidget: Text(
              CurrencyHelper.formatVND(room['price']),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.payments_outlined,
            label: "Tiền cọc",
            value: CurrencyHelper.formatVND(room['deposit']),
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.square_foot_outlined,
            label: "Diện tích",
            value: "${room['area']} m²",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.people_outline,
            label: "Giới hạn khách",
            value: "${room['max_tenants'] ?? 0} người",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.tag,
            label: "Mã số phòng",
            value: "RM-${room['id'].toString().padLeft(4, '0')}",
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 8);
  }

  Widget _buildRoomImage(Map<String, dynamic> room) {
    final List<dynamic> images = room['images_list'] ?? [];
    if (images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 60, color: Colors.black12),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) {
            return Image.network(
              "${ApiConstants.serverUrl}/uploads/rooms/${images[index]}",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.meeting_room_outlined,
                color: Colors.black12,
                size: 60,
              ),
            );
          },
        ),
        if (_currentImageIndex > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.chevron_left, color: Colors.white),
              ),
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        if (_currentImageIndex < images.length - 1)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.chevron_right, color: Colors.white),
              ),
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${_currentImageIndex + 1}/${images.length}",
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsBottomSheet(
    BuildContext context,
    Map<String, dynamic> room,
  ) {
    AppOptionsSheet.show(
      context: context,
      options: [
        AppOptionItem(
          label: "Cập nhật thông tin",
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRoomScreen(roomData: room),
              ),
            );
            if (result == true) {
              ref.refresh(
                roomDetailProvider("${widget.roomId}_${widget.houseId}").future,
              );
              setState(() => _hasChanged = true);
            }
          },
        ),
        AppOptionItem(
          label: "Xóa phòng này",
          isDestructive: true,
          onTap: () => _deleteRoomConfirm(room),
        ),
      ],
    );
  }
}
