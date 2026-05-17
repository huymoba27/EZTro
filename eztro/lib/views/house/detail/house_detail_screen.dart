import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models & Screens
import '../../../models/house_model.dart';
import '../create/create_house_screen.dart';
import '../providers/house_notifier.dart';

// Core Resources
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/dialog_helper.dart';

// Widgets & Components
import 'widgets/house_detail_widgets.dart';
import 'package:eztro/core/widgets/widgets.dart';

class HouseDetailScreen extends ConsumerStatefulWidget {
  final int houseId;
  const HouseDetailScreen({super.key, required this.houseId});

  @override
  ConsumerState<HouseDetailScreen> createState() => _HouseDetailScreenState();
}

class _HouseDetailScreenState extends ConsumerState<HouseDetailScreen> {
  bool isLocalLoading = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final housesAsync = ref.watch(houseNotifierProvider);

    return housesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text("Lỗi")),
        body: Center(child: Text("Không thể tải thông tin: $err")),
      ),
      data: (houses) {
        // Tìm nhà trong danh sách
        HouseModel currentHouse;
        try {
          currentHouse = houses.firstWhere((h) => h.id == widget.houseId);
        } catch (e) {
          // Nếu không tìm thấy (đã xóa), hiện loading để đợi dialog success xử lý pop
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          appBar: CustomAppBar(
            title: "CHI TIẾT NHÀ",
            onBack: () => Navigator.of(context).pop(_hasChanged),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () => _showOptionsBottomSheet(context, currentHouse),
              ),
            ],
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () =>
                    ref.read(houseNotifierProvider.notifier).refresh(),
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    HouseDetailHeader(house: currentHouse),
                    HouseInfoSection(house: currentHouse),
                    HouseAmenitiesSection(house: currentHouse),
                  ],
                ),
              ),
              if (isLocalLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsBottomSheet(BuildContext context, HouseModel house) {
    AppOptionsSheet.show(
      context: context,
      options: [
        AppOptionItem(
          label: "Cập nhật thông tin",
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateHouseScreen(house: house),
              ),
            );
            if (result == true) {
              ref.read(houseNotifierProvider.notifier).refresh();
              setState(() => _hasChanged = true);
            }
          },
        ),
        AppOptionItem(
          label: "Xóa nhà trọ",
          isDestructive: true,
          onTap: () => _deleteHouse(context, house),
        ),
      ],
    );
  }

  void _deleteHouse(BuildContext context, HouseModel house) {
    if (house.totalRooms > 0) {
      DialogHelper.showWarning(
        context,
        "Không thể xóa khu trọ đang có ${house.totalRooms} phòng. Vui lòng xóa hết phòng trước khi thực hiện thao tác này!",
      );
      return;
    }

    DialogHelper.showConfirmDialog(
      context: context,
      title: "XÁC NHẬN XÓA",
      message:
          "Bạn có chắc chắn muốn xóa nhà trọ này? Mọi dữ liệu sẽ mất vĩnh viễn.",
      onConfirm: () async {
        setState(() => isLocalLoading = true);
        try {
          var result = await ref
              .read(houseNotifierProvider.notifier)
              .deleteHouse(house.id);
          if (result['status'] == 'success') {
            if (mounted) {
              DialogHelper.showSuccess(
                context,
                "Đã xóa nhà trọ thành công!",
                onTap: () {
                  Navigator.of(context).pop(true); // Quay về danh sách
                },
              );
            }
          } else {
            if (mounted) {
              DialogHelper.showError(
                context,
                result['message'] ?? "Không thể xóa nhà trọ này.",
              );
            }
          }
        } finally {
          if (mounted) setState(() => isLocalLoading = false);
        }
      },
    );
  }
}
