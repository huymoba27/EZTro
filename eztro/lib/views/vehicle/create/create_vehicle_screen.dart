import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/vehicle_service.dart';
import '../../../services/house_service.dart';
import '../../../models/house_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/custom_painters.dart';
import '../../../core/constants/app_colors.dart';

class CreateVehicleScreen extends StatefulWidget {
  const CreateVehicleScreen({super.key});

  @override
  State<CreateVehicleScreen> createState() => _CreateVehicleScreenState();
}

class _CreateVehicleScreenState extends State<CreateVehicleScreen> {
  bool isLoading = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<HouseModel> allHouses = [];
  List<Map<String, dynamic>> roomsWithService = [];
  List<Map<String, dynamic>> availableTenants = [];

  HouseModel? selectedHouse;
  Map<String, dynamic>? selectedRoom;
  Map<String, dynamic>? selectedTenant;

  final plateController = TextEditingController();
  final typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final houses = await HouseService.getHousesWithContracts();
      List<HouseModel> filteredHouses = [];

      for (var house in houses) {
        final rooms = await VehicleService.getRoomsWithVehicleService(
          houseId: house.id,
        );
        bool hasPending = false;
        for (var room in rooms) {
          final tenants = await VehicleService.getTenantsWithVehicles(
            roomId: int.parse(room['id'].toString()),
          );
          if (tenants.any((t) => (t['vehicles'] as List).isEmpty)) {
            hasPending = true;
            break;
          }
        }
        if (hasPending) filteredHouses.add(house);
      }
      setState(() => allHouses = filteredHouses);
    } catch (e) {
      debugPrint("Lỗi: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openHouseModal() {
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
      subtitle: "Vui lòng chọn khu trọ đăng ký",
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
          });
          setState(() => isLoading = true);
          final rooms = await VehicleService.getRoomsWithVehicleService(
            houseId: id,
          );
          setState(() {
            roomsWithService = rooms;
            isLoading = false;
          });
        }
      },
    );
  }

  void _openRoomModal() {
    if (selectedHouse == null) {
      return DialogHelper.showWarning(context, "Vui lòng chọn nhà!");
    }

    AppSelectModal.show<String>(
      context: context,
      title: "CHỌN PHÒNG",
      subtitle: "Tại ${selectedHouse!.houseName}",
      searchPlaceholder: "Tìm tên phòng...",
      items: roomsWithService
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
          final room = roomsWithService.firstWhere(
            (r) => r['room_name'] == val,
          );
          setState(() {
            selectedRoom = room;
            selectedTenant = null;
            isLoading = true;
          });
          final tenants = await VehicleService.getTenantsWithVehicles(
            roomId: int.parse(room['id'].toString()),
          );
          final filtered = tenants
              .where((t) => (t['vehicles'] as List).isEmpty)
              .toList();
          setState(() {
            availableTenants = filtered;
            isLoading = false;
          });
        }
      },
    );
  }

  void _openTenantModal() {
    if (selectedRoom == null) {
      return DialogHelper.showWarning(context, "Vui lòng chọn phòng!");
    }
    if (availableTenants.isEmpty) {
      return DialogHelper.showWarning(
        context,
        "Phòng này đã đăng ký xe hết rồi!",
      );
    }

    AppSelectModal.show<String>(
      context: context,
      title: "CHỌN CHỦ XE",
      subtitle: "Khách chưa có xe tại phòng ${selectedRoom!['room_name']}",
      searchPlaceholder: "Tìm tên khách...",
      items: availableTenants
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
            () => selectedTenant = availableTenants.firstWhere(
              (t) => t['tenant_name'] == values.first,
            ),
          );
        }
      },
    );
  }

  void _submit() async {
    if (selectedTenant == null || plateController.text.isEmpty) {
      return DialogHelper.showWarning(context, "Vui lòng điền đủ thông tin!");
    }
    setState(() => isLoading = true);
    try {
      final res = await VehicleService.addVehicle(
        tenantId: int.parse(selectedTenant!['id'].toString()),
        plate: plateController.text.trim(),
        type: typeController.text.trim(),
        image: _imageFile,
      );
      if (res['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          "Đăng ký thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message'] ?? "Lỗi");
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fillDemoData() async {
    final data = DemoData.vehicle;
    final house =
        selectedHouse ?? (allHouses.isNotEmpty ? allHouses.first : null);

    setState(() {
      selectedHouse = house;
      selectedRoom = null;
      selectedTenant = null;
      plateController.text = data.plate;
      typeController.text = data.type;
    });

    if (house == null) return;

    setState(() => isLoading = true);
    try {
      final rooms = await VehicleService.getRoomsWithVehicleService(
        houseId: house.id,
      );
      Map<String, dynamic>? pickedRoom;
      Map<String, dynamic>? pickedTenant;
      List<Map<String, dynamic>> tenants = [];

      for (final room in rooms) {
        final roomTenants = await VehicleService.getTenantsWithVehicles(
          roomId: int.parse(room['id'].toString()),
        );
        final pendingTenants = roomTenants
            .where((t) => (t['vehicles'] as List).isEmpty)
            .toList();
        if (pendingTenants.isNotEmpty) {
          pickedRoom = room;
          pickedTenant = pendingTenants.first;
          tenants = pendingTenants;
          break;
        }
      }

      if (mounted) {
        setState(() {
          roomsWithService = rooms;
          selectedRoom = pickedRoom;
          selectedTenant = pickedTenant;
          availableTenants = tenants;
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: "ĐĂNG KÝ XE MỚI",
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DevAutofillButton(onPressed: _fillDemoData),
                  AppSectionCard(
                    title: "Vị trí & Chủ sở hữu",
                    child: Column(
                      children: [
                        CustomSelectField(
                          label: "Nhà trọ *",
                          value: selectedHouse?.houseName ?? "Chọn nhà trọ",
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
                              "Chọn người đăng ký",
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
                    title: "Hình ảnh thực tế",
                    child: _buildImagePickerSection(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return GestureDetector(
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
        painter: _imageFile == null
            ? DashedRectPainter(
                color: Colors.black.withOpacity(0.15),
                dash: 6,
                gap: 4,
                strokeWidth: 2,
              )
            : null,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: _imageFile != null
                ? Border.all(color: Colors.black.withOpacity(0.15), width: 0.8)
                : null,
          ),
          child: _imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Nhấn để tải ảnh xe lên",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return AppBottomButtons(
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      cancelText: "Hủy bỏ",
      confirmText: "Đăng ký xe",
      isSubmitting: isLoading,
    );
  }
}
