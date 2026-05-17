import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../utils/dialog_helper.dart';

/// Ô nhập text chuẩn, dùng trong các form tạo/sửa.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final Function(String)? onChanged;
  final bool readOnly;
  final FocusNode? focusNode;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.readOnly = false,
    this.focusNode,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            readOnly: readOnly,
            maxLines: maxLines,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.normal,
            ),
            decoration: InputDecoration(
              hintText: hint ?? label,
              counterText: maxLength == null ? null : "",
              hintStyle: const TextStyle(fontSize: 14, color: Colors.black26),
              isDense: true,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF8F9FA),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 0.8,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô chọn (dropdown style) chuẩn, dùng trong các form tạo/sửa.
class CustomSelectField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? lockedMessage;

  const CustomSelectField({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.lockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nhãn nằm ngoài, phía trên ô chọn
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),

          // 2. Ô chọn chính
          InkWell(
            onTap:
                onTap ??
                (lockedMessage == null
                    ? null
                    : () => DialogHelper.showWarning(context, lockedMessage!)),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black.withOpacity(0.15),
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            (value.contains("Chọn") ||
                                value.contains("Chưa chọn"))
                            ? Colors.black26
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
