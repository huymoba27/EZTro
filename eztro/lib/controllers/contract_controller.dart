import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/contract_service.dart';
import '../services/deposit_service.dart';
import '../services/notification_service.dart';
import '../core/utils/dialog_helper.dart';
import '../core/utils/input_validation_helper.dart';
import '../models/contract_model.dart';
import '../models/room_model.dart';
import '../services/auth_service.dart';

class ContractController {
  // 🎯 Tính ngày kết thúc hợp đồng
  static String calculateEndDate(String startDateStr, String durationStr) {
    try {
      DateTime start = DateTime.tryParse(startDateStr) ?? DateTime.now();
      int months = int.tryParse(durationStr) ?? 0;
      if (months > 0) {
        DateTime end = DateTime(
          start.year,
          start.month + months,
          start.day,
        ).subtract(const Duration(days: 1));
        return DateFormat('yyyy-MM-dd').format(end);
      }
    } catch (e) {
      debugPrint("Lỗi tính ngày kết thúc: $e");
    }
    return "Chưa xác định";
  }

  // 🎯 Xử lý Lưu / Cập nhật hợp đồng
  static Future<void> handleSave({
    required BuildContext context,
    required bool isEdit,
    required ContractModel? contractData,
    required RoomModel? selectedRoom,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController priceController,
    required TextEditingController depositController,
    required TextEditingController paymentDayController,
    required TextEditingController startElectricController,
    required TextEditingController startWaterController,
    required TextEditingController idCardController,
    required TextEditingController emailController,
    required TextEditingController birthdayController,
    required TextEditingController idCardDateController,
    required TextEditingController idCardPlaceController,
    required TextEditingController addressController,
    required TextEditingController startDateController,
    required String endDateDisplay,
    required String selectedGender,
    required List<int> selectedServiceIds,
    required dynamic frontImg,
    required dynamic backImg,
    required Function(bool) setSubmitting,
    int? depositId,
  }) async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      DialogHelper.showWarning(
        context,
        "Vui lòng điền đủ tên và số điện thoại!",
      );
      return;
    }

    final phoneError = InputValidationHelper.phoneError(phoneController.text);
    if (phoneError != null) {
      DialogHelper.showWarning(context, phoneError);
      return;
    }

    final price = double.tryParse(priceController.text.replaceAll(',', ''));
    final deposit = double.tryParse(depositController.text.replaceAll(',', ''));
    final paymentDay = int.tryParse(paymentDayController.text.trim());
    final startElectric = int.tryParse(startElectricController.text.trim());
    final startWater = int.tryParse(startWaterController.text.trim());

    if (price == null || price <= 0) {
      DialogHelper.showWarning(context, "Giá thuê phải là số lớn hơn 0.");
      return;
    }
    if (deposit == null || deposit < 0) {
      DialogHelper.showWarning(context, "Tiền cọc phải là số không âm.");
      return;
    }
    if (paymentDay == null || paymentDay < 1 || paymentDay > 31) {
      DialogHelper.showWarning(
        context,
        "Ngày thu tiền phải nằm trong khoảng 1-31.",
      );
      return;
    }
    if (startElectric == null || startElectric < 0) {
      DialogHelper.showWarning(
        context,
        "Chỉ số điện đầu kỳ phải là số không âm.",
      );
      return;
    }
    if (startWater == null || startWater < 0) {
      DialogHelper.showWarning(
        context,
        "Chỉ số nước đầu kỳ phải là số không âm.",
      );
      return;
    }

    setSubmitting(true);
    try {
      int? roomId;
      if (isEdit) {
        roomId = contractData!.roomId;
      } else {
        roomId = selectedRoom?.id;
      }

      if (roomId == null) {
        DialogHelper.showError(context, "Lỗi: Không tìm thấy ID phòng!");
        return;
      }

      Map<String, dynamic> res;
      if (isEdit) {
        int contractId = contractData!.id;
        res = await ContractService.updateContract(
          roomId: roomId,
          contractId: contractId,
          price: price,
          deposit: deposit,
          paymentDay: paymentDay,
          startElectric: startElectric,
          startWater: startWater,
          serviceIds: selectedServiceIds,
        );
      } else {
        res = await ContractService.createContract(
          roomId: roomId,
          customerName: nameController.text.trim(),
          phone: phoneController.text.trim(),
          password: "",
          idCard: idCardController.text.trim(),
          gender: selectedGender,
          email: emailController.text.trim(),
          birthday: birthdayController.text.trim(),
          idCardDate: idCardDateController.text,
          idCardPlace: idCardPlaceController.text,
          address: addressController.text,
          price: price,
          deposit: deposit,
          startDate: startDateController.text,
          endDate: endDateDisplay == "Chưa xác định" ? "" : endDateDisplay,
          createDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          paymentDay: paymentDay,
          serviceIds: selectedServiceIds,
          startElectric: startElectric,
          startWater: startWater,
          depositId: depositId,
          imageFront: frontImg,
          imageBack: backImg,
        );
      }

      if (res['status'] == 'success') {
        if (depositId != null) {
          await DepositService.updateStatus(depositId, 'completed');
        }

        // 1. Gửi thông báo cho khách thuê
        if (res['data']?['tenant_id'] != null) {
          NotificationService.pushNotification(
            userId: int.parse(res['data']['tenant_id'].toString()),
            title: isEdit ? "Cập nhật hợp đồng" : "Hợp đồng mới đã ký",
            description: isEdit
                ? "Hợp đồng phòng ${contractData?.roomName} vừa được cập nhật thông tin."
                : "Chúc mừng! Hợp đồng thuê phòng ${selectedRoom?.roomName} của bạn đã được ký kết thành công.",
            type: "contract",
            metadata: {"contract_id": res['data']?['id']},
          );
        }

        // 2. Gửi thông báo cho chủ trọ (người thực hiện)
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null) {
          NotificationService.pushNotification(
            userId: currentUser.id,
            title: isEdit ? "Cập nhật hợp đồng" : "Hợp đồng mới đã ký",
            description: isEdit
                ? "Bạn đã cập nhật thông tin hợp đồng cho phòng ${contractData?.roomName}."
                : "Bạn đã ký kết thành công hợp đồng cho phòng ${selectedRoom?.roomName}.",
            type: "contract",
            metadata: {"contract_id": res['data']?['id']},
          );
        }

        DialogHelper.showSuccess(
          context,
          isEdit
              ? "Đã cập nhật hợp đồng thành công!"
              : "Đã ký kết hợp đồng thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message'] ?? "Lỗi từ máy chủ");
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi: $e");
    } finally {
      setSubmitting(false);
    }
  }
}
