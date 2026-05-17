import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../controllers/tenant_controller.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/input_validation_helper.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_painters.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  // Model state
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<HouseModel> allHouses = [];
  List<RoomModel> occupiedRooms = [];
  HouseModel? selectedHouse;
  RoomModel? selectedRoom;

  // Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();
  final idCardController = TextEditingController();
  final idCardDateController = TextEditingController();
  final idCardPlaceController = TextEditingController();
  final addressController = TextEditingController();

  String selectedGender = "Nam";
  XFile? _frontImageFile, _backImageFile;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      final houses = await HouseService.getHouses();
      final rooms = await RoomService.getRoomsWithSpace();
      if (mounted) {
        setState(() {
          allHouses = houses;
          occupiedRooms = rooms;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImageFile = image;
        } else {
          _backImageFile = image;
        }
      });
    }
  }

  void _handleConfirm() {
    if (selectedRoom == null) {
      DialogHelper.showWarning(context, "Vui lòng chọn phòng ở ghép!");
      return;
    }
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      DialogHelper.showWarning(context, "Vui lòng nhập tên và số điện thoại!");
      return;
    }
    final phoneError = InputValidationHelper.phoneError(phoneController.text);
    if (phoneError != null) {
      DialogHelper.showWarning(context, phoneError);
      return;
    }

    TenantController.addMember(
      context: context,
      selectedRoom: selectedRoom?.toJson(),
      nameController: nameController,
      phoneController: phoneController,
      emailController: emailController,
      birthdayController: birthdayController,
      idCardController: idCardController,
      idCardDateController: idCardDateController,
      idCardPlaceController: idCardPlaceController,
      addressController: addressController,
      selectedGender: selectedGender,
      frontImg: _frontImageFile != null ? File(_frontImageFile!.path) : null,
      backImg: _backImageFile != null ? File(_backImageFile!.path) : null,
      setSubmitting: (val) => setState(() => _isSubmitting = val),
    );
  }

  void _fillDemoData() {
    final data = DemoData.member;
    setState(() {
      if (selectedRoom == null && occupiedRooms.isNotEmpty) {
        selectedRoom = occupiedRooms.first;
        for (final house in allHouses) {
          if (house.id.toString() == selectedRoom!.houseId.toString()) {
            selectedHouse = house;
            break;
          }
        }
      }

      nameController.text = data.name;
      phoneController.text = data.phone;
      emailController.text = data.email;
      birthdayController.text = data.birthday;
      idCardController.text = data.idCard;
      idCardDateController.text = data.idCardDate;
      idCardPlaceController.text = data.idCardPlace;
      addressController.text = data.address;
      selectedGender = data.gender;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "THÊM THÀNH VIÊN",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      DevAutofillButton(onPressed: _fillDemoData),
                      AppSectionCard(
                        title: "Vị trí phòng",
                        child: Column(
                          children: [
                            CustomSelectField(
                              label: "Nhà trọ *",
                              value:
                                  selectedHouse?.houseName ??
                                  "Chọn nhà có phòng ở ghép",
                              onTap: _openHouseModal,
                            ),
                            CustomSelectField(
                              label: "Phòng đang thuê *",
                              value:
                                  selectedRoom?.roomName ??
                                  "Chọn phòng để ở ghép",
                              onTap: _openRoomModal,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedRoom != null) ...[
                        AppSectionCard(
                          title: "Thông tin thành viên mới",
                          child: Column(
                            children: [
                              CustomTextField(
                                label: "Họ và tên *",
                                hint: "Nhập họ tên đầy đủ",
                                controller: nameController,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      label: "Số điện thoại *",
                                      hint: "09xxx",
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      maxLength: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomSelectField(
                                      label: "Giới tính",
                                      value: selectedGender,
                                      onTap: _showGenderPicker,
                                    ),
                                  ),
                                ],
                              ),
                              CustomSelectField(
                                label: "Ngày sinh",
                                value: birthdayController.text.isEmpty
                                    ? "Chọn ngày sinh"
                                    : birthdayController.text,
                                onTap: () =>
                                    _showDatePicker(birthdayController, "1900"),
                              ),
                              CustomTextField(
                                label: "Địa chỉ thường trú",
                                hint: "Địa chỉ trên CCCD",
                                controller: addressController,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppSectionCard(
                          title: "Định danh (CCCD)",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                label: "Số CCCD",
                                hint: "Nhập số định danh",
                                controller: idCardController,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomSelectField(
                                      label: "Ngày cấp",
                                      value: idCardDateController.text.isEmpty
                                          ? "Chọn ngày"
                                          : idCardDateController.text,
                                      onTap: () => _showDatePicker(
                                        idCardDateController,
                                        "1950",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomTextField(
                                      label: "Nơi cấp",
                                      hint: "Cục CS QLHC...",
                                      controller: idCardPlaceController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Ảnh chụp CCCD",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildIdCardPicker(true)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildIdCardPicker(false)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          if (selectedRoom != null) _buildBottomButtons(),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdCardPicker(bool isFront) {
    final file = isFront ? _frontImageFile : _backImageFile;
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: CustomPaint(
        painter: file == null
            ? DashedRectPainter(
                color: Colors.black.withOpacity(0.15),
                dash: 4,
                gap: 4,
                strokeWidth: 1.5,
              )
            : null,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: file != null
                ? Border.all(color: Colors.black.withOpacity(0.1), width: 0.8)
                : null,
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(file.path), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary.withOpacity(0.5),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFront ? "Mặt trước" : "Mặt sau",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withOpacity(0.7),
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AppBottomButtons(
        onCancel: () => Navigator.pop(context),
        onConfirm: _handleConfirm,
        cancelText: "Hủy bỏ",
        confirmText: "Xác nhận ngay",
        isSubmitting: _isSubmitting,
      ),
    );
  }

  void _openHouseModal() {
    final housesWithSpace = allHouses
        .where(
          (h) =>
              occupiedRooms.any((r) => r.houseId.toString() == h.id.toString()),
        )
        .toList();

    if (housesWithSpace.isEmpty) {
      DialogHelper.showWarning(context, "Không có phòng nào còn chỗ!");
      return;
    }

    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
      subtitle: "Lọc dữ liệu theo nhà trọ",
      items: housesWithSpace
          .map((h) => AppSelectItem(label: h.houseName, value: h.id))
          .toList(),
      initialValues: selectedHouse != null ? [selectedHouse!.id] : [],
      onSelect: (values) {
        if (values.isNotEmpty) {
          setState(() {
            selectedHouse = allHouses.firstWhere((h) => h.id == values.first);
            selectedRoom = null;
          });
        }
      },
    );
  }

  void _openRoomModal() {
    if (selectedHouse == null) return;
    final roomsInHouse = occupiedRooms
        .where((r) => r.houseId.toString() == selectedHouse!.id.toString())
        .toList();

    DialogHelper.showLocationSelect(
      context: context,
      title: "CHỌN PHÒNG Ở GHÉP",
      subtitle: "Tại ${selectedHouse!.houseName}",
      data: roomsInHouse.map((r) => r.roomName).toList(),
      currentValue: selectedRoom?.roomName ?? "",
      onSelect: (val) => setState(
        () => selectedRoom = roomsInHouse.firstWhere((r) => r.roomName == val),
      ),
    );
  }

  void _showGenderPicker() {
    DialogHelper.showLocationSelect(
      context: context,
      title: "CHỌN GIỚI TÍNH",
      subtitle: "Thông tin thành viên",
      data: const ["Nam", "Nữ", "Khác"],
      currentValue: selectedGender,
      onSelect: (val) => setState(() => selectedGender = val),
      showSearch: false,
    );
  }

  void _showDatePicker(TextEditingController controller, String startYear) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(int.parse(startYear)),
      lastDate: DateTime.now(),
    ).then((d) {
      if (d != null) {
        setState(() => controller.text = DateFormat('yyyy-MM-dd').format(d));
      }
    });
  }
}
