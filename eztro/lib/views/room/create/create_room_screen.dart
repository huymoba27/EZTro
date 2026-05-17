import 'dart:io';
import 'package:eztro/services/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eztro/services/house_service.dart';
import 'package:eztro/models/house_model.dart';
import 'package:eztro/controllers/room_controller.dart';
import 'package:eztro/core/utils/custom_painters.dart';
import 'package:eztro/core/utils/dialog_helper.dart';
import 'package:eztro/core/test_tools/demo_data.dart';
import 'package:eztro/core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'package:eztro/core/constants/app_colors.dart';
import 'package:eztro/views/house/providers/house_notifier.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? roomData;
  final int? houseId;

  const CreateRoomScreen({super.key, this.houseId, this.roomData});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool isEditMode = false;

  final List<XFile> _images = [];
  final List<String> _existingImages = [];
  final List<String> _imagesToDelete = [];
  final ImagePicker _picker = ImagePicker();

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final areaController = TextEditingController();
  final depositController = TextEditingController();
  final maxTenantsController = TextEditingController();

  List<HouseModel> _houses = [];
  HouseModel? selectedHouse;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.roomData != null;
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      _houses = await HouseService.getHouses();

      if (isEditMode) {
        nameController.text = widget.roomData!['room_name'] ?? "";
        priceController.text = widget.roomData!['price']?.toString() ?? "";
        areaController.text = widget.roomData!['area']?.toString() ?? "";
        depositController.text = widget.roomData!['deposit']?.toString() ?? "";
        maxTenantsController.text =
            widget.roomData!['max_tenants']?.toString() ?? "";

        int hId = int.tryParse(widget.roomData!['house_id'].toString()) ?? 0;
        selectedHouse = _houses.firstWhere(
          (h) => h.id == hId,
          orElse: () => _houses.first,
        );
        _existingImages.clear();
        _existingImages.addAll(
          List<String>.from(widget.roomData!['images_list'] ?? []),
        );
      } else if (widget.houseId != null) {
        selectedHouse = _houses.firstWhere(
          (h) => h.id == widget.houseId,
          orElse: () => _houses.first,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() {
    RoomController.submitRoom(
      context: context,
      isEditMode: isEditMode,
      roomId: int.tryParse(widget.roomData?['id']?.toString() ?? ''),
      houseId: selectedHouse?.id,
      name: nameController.text.trim(),
      price: priceController.text.trim(),
      area: areaController.text.trim(),
      deposit: depositController.text.trim(),
      maxTenants: maxTenantsController.text.trim(),
      images: _images.map((x) => File(x.path)).toList(),
      deletedImages: _imagesToDelete,
      setSubmitting: (val) => setState(() => _isSubmitting = val),
      onSuccess: () {
        // Refresh danh sách nhà để cập nhật số lượng phòng
        ref.read(houseNotifierProvider.notifier).refresh();
      },
    );
  }

  void _fillDemoData() {
    final data = DemoData.room;
    setState(() {
      selectedHouse ??= _houses.isNotEmpty ? _houses.first : null;
      nameController.text = data.name;
      priceController.text = data.price;
      areaController.text = data.area;
      depositController.text = data.deposit;
      maxTenantsController.text = data.maxTenants;
    });
  }

  void _showHouseSelectModal() {
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
      subtitle: "Vui lòng chọn khu trọ cho phòng này",
      items: _houses
          .map((h) => AppSelectItem(label: h.houseName, value: h.id))
          .toList(),
      initialValues: selectedHouse != null ? [selectedHouse!.id] : [],
      onSelect: (values) {
        if (values.isNotEmpty) {
          setState(() {
            selectedHouse = _houses.firstWhere((h) => h.id == values.first);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: isEditMode ? "CẬP NHẬT PHÒNG" : "TẠO PHÒNG MỚI",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            if (!isEditMode)
                              DevAutofillButton(onPressed: _fillDemoData),
                            AppSectionCard(
                              title: "Vị trí",
                              child: CustomSelectField(
                                label: "Nhà trọ *",
                                value: selectedHouse?.houseName ?? "Chọn nhà",
                                onTap: _showHouseSelectModal,
                              ),
                            ),
                            _buildDivider(),
                            AppSectionCard(
                              title: "Thông tin chung",
                              child: CustomTextField(
                                controller: nameController,
                                label: "Tên phòng *",
                                hint: "VD: P.101",
                              ),
                            ),
                            _buildDivider(),
                            AppSectionCard(
                              title: "Giá & Diện tích",
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: priceController,
                                          label: "Giá thuê (VNĐ) *",
                                          keyboardType: TextInputType.number,
                                          hint: "Nhập giá",
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomTextField(
                                          controller: areaController,
                                          label: "Diện tích (m²)",
                                          keyboardType: TextInputType.number,
                                          hint: "M2",
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: depositController,
                                          label: "Tiền cọc (VNĐ)",
                                          keyboardType: TextInputType.number,
                                          hint: "Nhập cọc",
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomTextField(
                                          controller: maxTenantsController,
                                          label: "Khách tối đa",
                                          keyboardType: TextInputType.number,
                                          hint: "Người",
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _buildDivider(),
                            AppSectionCard(
                              title: "Hình ảnh thực tế",
                              child: _buildImageGrid(),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
              _buildBottomButtons(),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 10);
  }

  Widget _buildBottomButtons() {
    return AppBottomButtons(
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      cancelText: "Hủy bỏ",
      confirmText: isEditMode ? "Lưu cập nhật" : "Tạo phòng ngay",
      isSubmitting: _isSubmitting,
    );
  }

  Widget _buildImageGrid() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      GestureDetector(
        onTap: () => DialogHelper.showImagePicker(
          context: context,
          allowMultiple: true,
          onImagesPicked: (files) {
            setState(() {
              _images.addAll(files.map((f) => XFile(f.path)));
            });
          },
        ),
        child: CustomPaint(
          painter: DashedRectPainter(
            color: Colors.black.withOpacity(0.15),
            dash: 5,
            gap: 3,
            strokeWidth: 1.0,
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ),
      ),
      // Ảnh cũ đã có trên server
      ..._existingImages.map(
        (img) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "${ApiConstants.serverUrl}/uploads/rooms/$img",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => setState(() {
                  _existingImages.remove(img);
                  _imagesToDelete.add(img);
                }),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      // Ảnh mới chọn từ thiết bị
      ..._images.map(
        (img) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(img.path),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => setState(() => _images.remove(img)),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
