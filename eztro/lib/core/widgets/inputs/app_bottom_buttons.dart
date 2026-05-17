import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'primary_button.dart';

/// A reusable bottom bar with dual buttons (Cancel/Confirm) 
/// styled after the Create Room/Contract screens.
class AppBottomButtons extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final String cancelText;
  final String confirmText;
  final bool isSubmitting;
  final Color? confirmColor;
  final bool showCancel;

  const AppBottomButtons({
    super.key,
    this.onCancel,
    required this.onConfirm,
    this.cancelText = "HỦY",
    this.confirmText = "XÁC NHẬN",
    this.isSubmitting = false,
    this.confirmColor,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // CANCEL BUTTON
            if (showCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    cancelText.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.grey, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            // CONFIRM BUTTON
            Expanded(
              child: PrimaryButton(
                label: confirmText,
                isLoading: false, // 🎯 Không hiện vòng xoay trong nút nữa để đồng bộ toàn app
                color: confirmColor ?? AppColors.primary,
                onPressed: isSubmitting ? null : onConfirm, // 🎯 Vô hiệu hóa nút khi đang xử lý
              ),
            ),
          ],
        ),
      ),
    );
  }
}
