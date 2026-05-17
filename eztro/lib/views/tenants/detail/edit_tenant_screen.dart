import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/tenant_service.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/input_validation_helper.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/custom_painters.dart';

class EditTenantScreen extends StatefulWidget {
  final Map<String, dynamic> tenant;

  const EditTenantScreen({super.key, required this.tenant});

  @override
  State<EditTenantScreen> createState() => _EditTenantScreenState();
}

class _EditTenantScreenState extends State<EditTenantScreen> {
  bool _isSubmitting = false;

  // Controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController birthdayController;
  late TextEditingController idCardController;
  late TextEditingController idCardDateController;
  late TextEditingController idCardPlaceController;
  late TextEditingController addressController;

  String selectedGender = "Nam";
  XFile? _frontImageFile, _backImageFile;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final t = widget.tenant;
    nameController = TextEditingController(
      text: t['tenant_name']?.toString() ?? "",
    );
    phoneController = TextEditingController(text: t['phone']?.toString() ?? "");
    emailController = TextEditingController(text: t['email']?.toString() ?? "");
    birthdayController = TextEditingController(
      text: t['birthday']?.toString() ?? "",
    );
    idCardController = TextEditingController(
      text: t['id_card']?.toString() ?? "",
    );
    idCardDateController = TextEditingController(
      text: t['id_card_date']?.toString() ?? "",
    );
    idCardPlaceController = TextEditingController(
      text: t['id_card_place']?.toString() ?? "",
    );
    addressController = TextEditingController(
      text: t['address']?.toString() ?? "",
    );
    selectedGender = t['gender'] ?? "Nam";
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    idCardController.dispose();
    idCardDateController.dispose();
    idCardPlaceController.dispose();
    addressController.dispose();
    super.dispose();
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

  void _handleUpdate() async {
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

    setState(() => _isSubmitting = true);
    try {
      final res = await TenantService.updateTenant(
        tenantId: int.parse(widget.tenant['id'].toString()),
        tenantName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        gender: selectedGender,
        birthday: birthdayController.text,
        email: emailController.text.trim(),
        idCard: idCardController.text.trim(),
        idCardDate: idCardDateController.text,
        idCardPlace: idCardPlaceController.text,
        address: addressController.text,
        imageFront: _frontImageFile != null
            ? File(_frontImageFile!.path)
            : null,
        imageBack: _backImageFile != null ? File(_backImageFile!.path) : null,
      );

      if (res['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          "Cập nhật thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message'] ?? "Lỗi cập nhật!");
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "CẬP NHẬT KHÁCH THUÊ",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                AppSectionCard(
                  title: "Thông tin cá nhân",
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
                        hint: "Nhập địa chỉ trên CCCD",
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
                              onTap: () =>
                                  _showDatePicker(idCardDateController, "1950"),
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
                const SizedBox(height: 12),
                AppSectionCard(
                  title: "Liên hệ khác",
                  child: CustomTextField(
                    label: "Email",
                    hint: "example@gmail.com",
                    controller: emailController,
                  ),
                ),
              ],
            ),
          ),
          _buildBottomButtons(),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Hủy bỏ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Lưu thay đổi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["Nam", "Nữ", "Khác"]
            .map(
              (g) => ListTile(
                title: Text(g, textAlign: TextAlign.center),
                onTap: () {
                  setState(() => selectedGender = g);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
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
