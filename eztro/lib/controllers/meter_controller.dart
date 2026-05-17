import 'dart:io';
import 'package:flutter/material.dart';
import '../services/meter_service.dart';
import '../services/notification_service.dart';
import '../models/meter_model.dart';
import '../core/utils/dialog_helper.dart';

class MeterController {
  static Future<void> submitData({
    required BuildContext context,
    required bool isEdit,
    required Map<String, dynamic>? meterData,
    required Map<String, dynamic>? selectedRoom,
    required TextEditingController electricController,
    required TextEditingController waterController,
    required int oldE,
    required int oldW,
    required int contractId,
    required int selectedMonth,
    required int selectedYear,
    File? electricImage,
    File? waterImage,
    required Function(bool) setSubmitting,
    required VoidCallback onSuccess,
  }) async {
    if (selectedRoom == null ||
        electricController.text.isEmpty ||
        waterController.text.isEmpty) {
      DialogHelper.showWarning(context, "Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    final newE = int.tryParse(electricController.text.trim());
    final newW = int.tryParse(waterController.text.trim());

    if (newE == null || newW == null) {
      DialogHelper.showWarning(context, "Chỉ số điện nước phải là số hợp lệ.");
      return;
    }

    if (newE < oldE || newW < oldW) {
      DialogHelper.showWarning(
        context,
        "Số mới không được nhỏ hơn số cũ ($oldE/$oldW)!",
      );
      return;
    }

    setSubmitting(true);
    try {
      final meter = MeterModel(
        id: isEdit ? int.tryParse(meterData!['id'].toString()) : null,
        contractId: contractId,
        roomId: int.parse(selectedRoom['id'].toString()),
        readingDate: DateTime.now().toString(),
        billingMonth: selectedMonth,
        billingYear: selectedYear,
        oldElectric: oldE,
        newElectric: newE,
        oldWater: oldW,
        newWater: newW,
        userId: 1,
      );

      final res = isEdit
          ? await MeterService.updateMeterReading(
              meter,
              electricImage: electricImage,
              waterImage: waterImage,
            )
          : await MeterService.saveMeterReading(
              meter,
              electricImage: electricImage,
              waterImage: waterImage,
            );

      if (res['status'] == 'success') {
        if (selectedRoom['tenant_id'] != null) {
          NotificationService.pushNotification(
            userId: int.parse(selectedRoom['tenant_id'].toString()),
            title: "Đã chốt số điện nước",
            description:
                "Phòng ${selectedRoom['room_name']} đã được chốt số điện nước tháng $selectedMonth/$selectedYear.",
            type: "utility",
            metadata: {"meter_id": res['data']?['id']},
          );
        }

        NotificationService.pushNotification(
          userId: 1,
          title: "Đã chốt số điện nước",
          description:
              "Bạn đã chốt số cho phòng ${selectedRoom['room_name']} tháng $selectedMonth/$selectedYear.",
          type: "utility",
          metadata: {"meter_id": res['data']?['id']},
        );

        DialogHelper.showSuccess(
          context,
          "Đã chốt số thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message'] ?? "Lỗi máy chủ");
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối hệ thống");
    } finally {
      setSubmitting(false);
    }
  }
}
