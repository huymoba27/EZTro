import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/custom_painters.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';

class CustomerInfoWidget extends StatefulWidget {
  final TextEditingController nameController,
      phoneController,
      emailController,
      birthdayController,
      idCardController,
      idCardDateController,
      idCardPlaceController,
      addressController;
  final String selectedGender;
  final Function(String) onGenderChanged;
  final Function(File?, File?) onImagesChanged;
  final VoidCallback onSelectCCCDDate;
  final VoidCallback onSelectBirthday;
  final bool readOnly;

  const CustomerInfoWidget({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.birthdayController,
    required this.idCardController,
    required this.idCardDateController,
    required this.idCardPlaceController,
    required this.addressController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onImagesChanged,
    required this.onSelectCCCDDate,
    required this.onSelectBirthday,
    this.readOnly = false,
  });

  @override
  State<CustomerInfoWidget> createState() => _CustomerInfoWidgetState();
}

class _CustomerInfoWidgetState extends State<CustomerInfoWidget> {
  bool isExpanded = false;
  File? _front, _back;

  Future<void> _pickImage(bool isFront) async {
    DialogHelper.showImagePicker(
      context: context,
      onImagesPicked: (files) {
        if (files.isEmpty) return;
        final file = files.first;
        setState(() {
          if (isFront) {
            _front = file;
          } else {
            _back = file;
          }
        });
        widget.onImagesChanged(_front, _back);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: widget.nameController,
          label: "Họ tên khách thuê *",
          hint: "Họ và tên...",
          enabled: !widget.readOnly,
        ),
        CustomTextField(
          controller: widget.phoneController,
          label: "Số điện thoại *",
          hint: "090...",
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 11,
          enabled: !widget.readOnly,
        ),

        if (!widget.readOnly)
          AnimatedCrossFade(
            firstChild: _buildExpandButton(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildGenderRow(),
                CustomTextField(
                  controller: widget.emailController,
                  label: "Email",
                  hint: "example@gmail.com",
                  keyboardType: TextInputType.emailAddress,
                ),

                CustomSelectField(
                  label: "Ngày sinh",
                  value: widget.birthdayController.text.isEmpty
                      ? "Chọn ngày sinh"
                      : widget.birthdayController.text,
                  onTap: widget.onSelectBirthday,
                ),

                CustomTextField(
                  controller: widget.idCardController,
                  label: "Số CCCD/CMND *",
                  hint: "Nhập số định danh...",
                ),

                CustomSelectField(
                  label: "Ngày cấp CCCD",
                  value: widget.idCardDateController.text.isEmpty
                      ? "Chọn ngày cấp"
                      : widget.idCardDateController.text,
                  onTap: widget.onSelectCCCDDate,
                ),

                CustomTextField(
                  controller: widget.idCardPlaceController,
                  label: "Nơi cấp",
                  hint: "Công an tỉnh/thành phố...",
                ),
                CustomTextField(
                  controller: widget.addressController,
                  label: "Địa chỉ thường trú",
                  hint: "Địa chỉ trên CCCD...",
                  maxLines: 2,
                ),

                const SizedBox(height: 12),
                const Text(
                  "Hình ảnh CCCD",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 10),
                _buildImagePickers(),
                const SizedBox(height: 16),
                _buildExpandButton(),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
      ],
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: () => setState(() => isExpanded = !isExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isExpanded ? "THU GỌN THÔNG TIN" : "THÊM THÔNG TIN CHI TIẾT",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderRow() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        const Text(
          "Giới tính: ",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        Radio(
          value: "Nam",
          groupValue: widget.selectedGender,
          activeColor: AppColors.primary,
          onChanged: (v) => widget.onGenderChanged(v!),
        ),
        const Text("Nam", style: TextStyle(fontSize: 13)),
        const SizedBox(width: 20),
        Radio(
          value: "Nữ",
          groupValue: widget.selectedGender,
          activeColor: AppColors.primary,
          onChanged: (v) => widget.onGenderChanged(v!),
        ),
        const Text("Nữ", style: TextStyle(fontSize: 13)),
      ],
    ),
  );

  Widget _buildImagePickers() => Row(
    children: [
      Expanded(child: _imgBox("Mặt trước", _front, true)),
      const SizedBox(width: 12),
      Expanded(child: _imgBox("Mặt sau", _back, false)),
    ],
  );

  Widget _imgBox(String label, File? file, bool isFront) {
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: CustomPaint(
        painter: file == null
            ? DashedRectPainter(
                color: Colors.black.withValues(alpha: 0.15),
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
                ? Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 0.8,
                  )
                : null,
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
