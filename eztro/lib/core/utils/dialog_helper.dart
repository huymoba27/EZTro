import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/inputs/app_select_modal.dart';
import '../widgets/display/empty_state_widget.dart';
import '../constants/app_colors.dart';

class DialogHelper {
  static void showLocationSelect({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<String> data,
    required String currentValue,
    required Function(String) onSelect,
    bool showAllOption = false,
    String allOptionText = "Tất cả",
    bool showSearch = true,
    double? heightFactor,
  }) {
    AppSelectModal.show<String>(
      context: context,
      title: title,
      subtitle: subtitle,
      searchable: showSearch,
      heightFactor: heightFactor,
      items: [
        if (showAllOption)
          AppSelectItem(label: allOptionText, value: allOptionText),
        ...data.map((item) => AppSelectItem(label: item, value: item)),
      ],
      initialValues: [currentValue],
      onSelect: (values) {
        if (values.isNotEmpty) {
          onSelect(values.first);
        }
      },
    );
  }

  static void showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showConfirm(
      context: context,
      title: title,
      message: message,
      onConfirm: onConfirm,
      confirmText: "XÓA",
      confirmColor: Colors.red,
    );
  }

  static void showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = "XÁC NHẬN",
    Color confirmColor = const Color(0xFF2E7D32),
  }) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.8),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "HỦY",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyState({
    String title = "Không có dữ liệu",
    String subtitle = "Dữ liệu sẽ hiển thị tại đây",
    IconData icon = Icons.receipt_long_outlined,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyStateWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
            ),
          ),
        );
      },
    );
  }

  // Các hàm Success, Error, Warning giữ nguyên...
  static void showCustomConfirm({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
    String confirmText = "XÁC NHẬN",
    Color confirmColor = const Color(0xFF2E7D32),
  }) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: content,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "HỦY",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showLoginRequired({
    required BuildContext context,
    required VoidCallback onLogin,
  }) {
    showConfirm(
      context: context,
      title: "Yêu cầu đăng nhập",
      message: "Bạn cần đăng nhập để sử dụng tính năng này.",
      confirmText: "ĐĂNG NHẬP",
      onConfirm: onLogin,
    );
  }

  static void showAwesomeDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onTap != null) onTap();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    VoidCallback? onTap,
  }) {
    showAwesomeDialog(
      context: context,
      title: "THÀNH CÔNG",
      message: message,
      color: const Color(0xFF2E7D32),
      icon: Icons.check_circle_rounded,
      onTap: onTap,
    );
  }

  static void showError(BuildContext context, String message) {
    showAwesomeDialog(
      context: context,
      title: "LỖI",
      message: message,
      color: Colors.redAccent,
      icon: Icons.error_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showAwesomeDialog(
      context: context,
      title: "THÔNG BÁO",
      message: message,
      color: Colors.orange,
      icon: Icons.priority_high_rounded,
    );
  }

  static void showReasonDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String hintText,
    required Function(String) onConfirm,
    String confirmText = "XÁC NHẬN",
    Color confirmColor = const Color(0xFF2E7D32),
    bool isRequired = false,
  }) {
    if (!context.mounted) return;
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "HỦY",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isRequired && controller.text.trim().isEmpty) {
                      // Có thể hiện một thông báo nhỏ ở đây nếu cần
                      return;
                    }
                    Navigator.pop(context);
                    onConfirm(controller.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showImagePicker({
    required BuildContext context,
    required Function(List<File>) onImagesPicked,
    bool allowMultiple = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    "CHỌN NGUỒN ẢNH",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Chụp ảnh mới',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Sử dụng máy ảnh để chụp trực tiếp'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    onImagesPicked([File(pickedFile.path)]);
                  }
                },
              ),
              const Divider(height: 1, indent: 70, endIndent: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  allowMultiple
                      ? 'Chọn từ thư viện (Nhiều ảnh)'
                      : 'Chọn từ thư viện',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  allowMultiple
                      ? 'Chọn một hoặc nhiều ảnh có sẵn'
                      : 'Chọn ảnh có sẵn từ thiết bị',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  if (allowMultiple) {
                    final pickedFiles = await picker.pickMultiImage(
                      imageQuality: 80,
                    );
                    if (pickedFiles.isNotEmpty) {
                      onImagesPicked(
                        pickedFiles.map((f) => File(f.path)).toList(),
                      );
                    }
                  } else {
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      onImagesPicked([File(pickedFile.path)]);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
