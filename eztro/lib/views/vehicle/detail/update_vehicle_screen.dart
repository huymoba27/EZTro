import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/vehicle_service.dart';
import '../../../services/house_service.dart';
import '../../../services/api_constants.dart';
import '../../../models/house_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/custom_painters.dart';

class UpdateVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const UpdateVehicleScreen({super.key, required this.vehicle});

  @override
  State<UpdateVehicleScreen> createState() => _UpdateVehicleScreenState();
}

class _UpdateVehicleScreenState extends State<UpdateVehicleScreen> {
  bool isLoading = false;

  File? _imageFile;
  String? _oldImageUrl;
  final ImagePicker _picker = ImagePicker();

  List<HouseModel> allHouses = [];
  List<Map<String, dynamic>> roomsInHouse = [];
  List<Map<String, dynamic>> tenantsInRoom = [];

  HouseModel? selectedHouse;
  Map<String, dynamic>? selectedRoom;
  Map<String, dynamic>? selectedTenant;

  final plateController = TextEditingController();
  final typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    plateController.dispose();
    typeController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    try {
      // 1. Tải danh sách nhà
      allHouses = await HouseService.getHousesWithContracts();

      plateController.text = widget.vehicle['plate_number'] ?? "";
      typeController.text = widget.vehicle['vehicle_type'] ?? "";
      _oldImageUrl = widget.vehicle['vehicle_image'];

      if (allHouses.isNotEmpty) {
        // 🎯 Tìm nhà cũ
        selectedHouse = allHouses.firstWhere(
          (h) => h.id.toString() == widget.vehicle['house_id'].toString(),
          orElse: () => allHouses.first,
        );

        // 🎯 Tải phòng và tìm phòng cũ
        roomsInHouse = await VehicleService.getRoomsWithVehicleService(
          houseId: selectedHouse!.id,
        );
        selectedRoom = roomsInHouse.firstWhere(
          (r) => r['id'].toString() == widget.vehicle['room_id'].toString(),
          orElse: () => roomsInHouse.isNotEmpty ? roomsInHouse.first : {},
        );

        // 🎯 Tải khách và tìm khách cũ
        if (selectedRoom != null && selectedRoom!.isNotEmpty) {
          tenantsInRoom = await VehicleService.getTenantsWithVehicles(
            roomId: int.parse(selectedRoom!['id'].toString()),
          );
          tenantsInRoom = tenantsInRoom.where((t) {
            final isCurrent =
                t['id'].toString() == widget.vehicle['tenant_id'].toString();
            final vehicles = t['vehicles'];
            final hasVehicle = vehicles is List && vehicles.isNotEmpty;
            return isCurrent || !hasVehicle;
          }).toList();
          selectedTenant = tenantsInRoom.firstWhere(
            (t) => t['id'].toString() == widget.vehicle['tenant_id'].toString(),
            orElse: () => tenantsInRoom.isNotEmpty ? tenantsInRoom.first : {},
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi init Update: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openHouseModal() {
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
      subtitle: "Vui lòng chọn khu trọ cập nhật",
      items: allHouses
          .map((h) => AppSelectItem(label: h.houseName, value: h.id))
          .toList(),
      initialValues: selectedHouse != null ? [selectedHouse!.id] : [],
      onSelect: (values) async {
        if (values.isNotEmpty) {
          final id = values.first;
          setState(() {
            selectedHouse = allHouses.firstWhere((h) => h.id == id);
            selectedRoom = null;
            selectedTenant = null;
            roomsInHouse = [];
          });
          setState(() => isLoading = true);
          final rooms = await VehicleService.getRoomsWithVehicleService(
            houseId: id,
          );
          if (!mounted) return;
          setState(() {
            roomsInHouse = rooms;
            isLoading = false;
          });
        }
      },
    );
  }

  void _openRoomModal() {
    if (selectedHouse == null) return;

    AppSelectModal.show<String>(
      context: context,
      title: "CHỌN PHÒNG",
      subtitle: "Tại ${selectedHouse!.houseName}",
      items: roomsInHouse
          .map(
            (r) => AppSelectItem(
              label: r['room_name'].toString(),
              value: r['room_name'].toString(),
            ),
          )
          .toList(),
      initialValues: selectedRoom != null ? [selectedRoom!['room_name']] : [],
      onSelect: (values) async {
        if (values.isNotEmpty) {
          final val = values.first;
          final room = roomsInHouse.firstWhere((r) => r['room_name'] == val);
          setState(() {
            selectedRoom = room;
            selectedTenant = null;
            isLoading = true;
          });
          final tenants = await VehicleService.getTenantsWithVehicles(
            roomId: int.parse(room['id'].toString()),
          );
          if (!mounted) return;
          setState(() {
            tenantsInRoom = tenants.where((t) {
              final isCurrent =
                  t['id'].toString() == widget.vehicle['tenant_id'].toString();
              final vehicles = t['vehicles'];
              final hasVehicle = vehicles is List && vehicles.isNotEmpty;
              return isCurrent || !hasVehicle;
            }).toList();
            isLoading = false;
          });
        }
      },
    );
  }

  void _openTenantModal() {
    if (selectedRoom == null) return;

    AppSelectModal.show<String>(
      context: context,
      title: "CHỌN CHỦ XE",
      subtitle: "Phòng ${selectedRoom!['room_name']}",
      items: tenantsInRoom
          .map(
            (t) => AppSelectItem(
              label: t['tenant_name'].toString(),
              value: t['tenant_name'].toString(),
            ),
          )
          .toList(),
      initialValues: selectedTenant != null
          ? [selectedTenant!['tenant_name']]
          : [],
      onSelect: (values) {
        if (values.isNotEmpty) {
          setState(
            () => selectedTenant = tenantsInRoom.firstWhere(
              (t) => t['tenant_name'] == values.first,
            ),
          );
        }
      },
    );
  }

  void _submitUpdate() async {
    if (selectedTenant == null || plateController.text.isEmpty) {
      DialogHelper.showWarning(context, "Vui lòng nhập đầy đủ thông tin!");
      return;
    }
    setState(() => isLoading = true);

    final res = await VehicleService.updateVehicle(
      vehicleId: int.parse(widget.vehicle['id'].toString()),
      tenantId: int.parse(selectedTenant!['id'].toString()),
      plate: plateController.text.trim(),
      type: typeController.text.trim(),
      image: _imageFile,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (res['status'] == 'success') {
      DialogHelper.showSuccess(
        context,
        "Cập nhật thành công!",
        onTap: () {
          Navigator.pop(context, true);
        },
      );
    } else {
      DialogHelper.showError(context, res['message'] ?? "Lỗi cập nhật");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: "CẬP NHẬT XE",
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AppSectionCard(
                    title: "Vị trí & Chủ sở hữu",
                    child: Column(
                      children: [
                        CustomSelectField(
                          label: "Nhà trọ *",
                          value: selectedHouse?.houseName ?? "Chọn nhà",
                          onTap: _openHouseModal,
                        ),
                        CustomSelectField(
                          label: "Phòng *",
                          value: selectedRoom?['room_name'] ?? "Chọn phòng",
                          onTap: _openRoomModal,
                        ),
                        CustomSelectField(
                          label: "Chủ xe *",
                          value:
                              selectedTenant?['tenant_name'] ??
                              "Chọn người thuê",
                          onTap: _openTenantModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSectionCard(
                    title: "Thông tin phương tiện",
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: plateController,
                          label: "Biển số xe *",
                          hint: "VD: 59-X1 12345",
                        ),
                        CustomTextField(
                          controller: typeController,
                          label: "Loại xe",
                          hint: "VD: Honda Vision",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSectionCard(
                    title: "Hình ảnh phương tiện",
                    child: _buildImageSection(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          AppBottomButtons(
            onCancel: () => Navigator.pop(context),
            onConfirm: _submitUpdate,
            cancelText: "Hủy bỏ",
            confirmText: "Lưu thay đổi",
            isSubmitting: isLoading,
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() => Container(
    padding: const EdgeInsets.all(16),
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ảnh minh họa phương tiện",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final XFile? pickedFile = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (pickedFile != null) {
              setState(() => _imageFile = File(pickedFile.path));
            }
          },
          child: CustomPaint(
            painter: DashedRectPainter(
              color: Colors.grey.shade400,
              dash: 5,
              gap: 3,
              strokeWidth: 1.2,
            ),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : (_oldImageUrl != null && _oldImageUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "${ApiConstants.baseImageUrl}/uploads/vehicles/$_oldImageUrl",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.add_a_photo_outlined,
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey,
                      size: 30,
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}
