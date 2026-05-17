import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/invoice_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../core/utils/dialog_helper.dart';

class InvoiceController {
  /// 🎯 Tính toán hóa đơn theo thời gian thực (Real-time calculation)
  static Map<String, dynamic>? calculateInvoice({
    required Map<String, dynamic>? billSummary,
    required String newElecStr,
    required String newWaterStr,
    required bool isProRata,
    required DateTime? startDate,
    required DateTime? endDate,
    required int selectedMonth,
    required int selectedYear,
  }) {
    if (billSummary == null) return null;

    int newE = int.tryParse(newElecStr) ?? 0;
    int newW = int.tryParse(newWaterStr) ?? 0;
    int oldE = int.parse(billSummary['old_elec'].toString());
    int oldW = int.parse(billSummary['old_water'].toString());

    int consumptionE = (newE > oldE) ? (newE - oldE) : 0;
    int consumptionW = (newW > oldW) ? (newW - oldW) : 0;

    double dayRatio = 1.0;
    int daysStayed = 0;
    if (isProRata && startDate != null && endDate != null) {
      int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
      daysStayed = endDate.difference(startDate).inDays + 1;
      if (daysStayed > 0) dayRatio = daysStayed / daysInMonth;
    }

    Map<String, dynamic> tempSummary = Map.from(billSummary);
    List tempDetails = List.from(tempSummary['details']);
    double currentTotal = 0;

    for (int i = 0; i < tempDetails.length; i++) {
      var item = Map<String, dynamic>.from(tempDetails[i]);
      if (item['type'] == 'electric') {
        item['quantity'] = consumptionE;
        item['subtotal'] = consumptionE * (double.tryParse(item['price'].toString()) ?? 0);
      } else if (item['type'] == 'water') {
        item['quantity'] = consumptionW;
        item['subtotal'] = consumptionW * (double.tryParse(item['price'].toString()) ?? 0);
      } else if (item['type'] == 'room') {
        double basePrice = double.tryParse(item['price'].toString()) ?? 0;
        if (isProRata && startDate != null && endDate != null) {
          item['subtotal'] = basePrice * dayRatio;
          item['quantity'] = daysStayed;
          item['unit'] = "ngày";
          if (!item['name'].contains("(Tính theo ngày)")) item['name'] = "${item['name']} (Tính theo ngày)";
        } else {
          item['subtotal'] = basePrice;
          item['quantity'] = 1;
          item['unit'] = "phòng";
          item['name'] = item['name'].replaceAll(" (Tính theo ngày)", "");
        }
      }
      tempDetails[i] = item;
      currentTotal += (double.tryParse(item['subtotal'].toString()) ?? 0);
    }

    tempSummary['details'] = tempDetails;
    tempSummary['total_amount'] = currentTotal;
    return tempSummary;
  }

  /// 🎯 Xử lý gửi hóa đơn lên server
  static Future<void> submitInvoice({
    required BuildContext context,
    required bool isMeterChecked,
    required TextEditingController elecController,
    required TextEditingController waterController,
    required Map<String, dynamic>? billSummary,
    required Map<String, dynamic>? selectedRoom,
    required int selectedMonth,
    required int selectedYear,
    required bool isProRata,
    required DateTime? startDate,
    required DateTime? endDate,
    required Function(bool) setLoading,
  }) async {
    if (billSummary == null || selectedRoom == null) return;

    if (!isMeterChecked && (elecController.text.isEmpty || waterController.text.isEmpty)) {
      DialogHelper.showWarning(context, "Vui lòng nhập số điện nước mới!");
      return;
    }

    if (!isMeterChecked) {
      int newE = int.tryParse(elecController.text) ?? 0;
      int newW = int.tryParse(waterController.text) ?? 0;
      int oldE = int.parse(billSummary['old_elec'].toString());
      int oldW = int.parse(billSummary['old_water'].toString());

      if (newE < oldE) {
        DialogHelper.showError(context, "Số điện mới ($newE) không được nhỏ hơn số cũ ($oldE)!");
        return;
      }
      if (newW < oldW) {
        DialogHelper.showError(context, "Số nước mới ($newW) không được nhỏ hơn số cũ ($oldW)!");
        return;
      }
    }

    setLoading(true);
    try {
      final res = await InvoiceService.createInvoiceWithMeter(
        roomId: selectedRoom['id'],
        month: selectedMonth,
        year: selectedYear,
        newElec: elecController.text,
        newWater: waterController.text,
        isMeterChecked: isMeterChecked,
        isProRata: isProRata,
        startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null,
        endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      );

      if (res['status'] == 'success') {
        // Thông báo cho khách thuê
        if (selectedRoom['tenant_id'] != null) {
          NotificationService.pushNotification(
            userId: int.parse(selectedRoom['tenant_id'].toString()),
            title: "Hóa đơn tiền phòng mới",
            description: "Hóa đơn tháng $selectedMonth/$selectedYear của phòng ${selectedRoom['room_name']} đã được lập. Vui lòng kiểm tra và thanh toán.",
            type: "invoice",
            metadata: {"invoice_id": res['data']?['id']},
          );
        }

        // Thông báo cho chủ trọ
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null) {
          NotificationService.pushNotification(
            userId: currentUser.id,
            title: "Đã lập hóa đơn",
            description: "Bạn đã lập thành công hóa đơn tháng $selectedMonth/$selectedYear cho phòng ${selectedRoom['room_name']}.",
            type: "invoice",
            metadata: {"invoice_id": res['data']?['id']},
          );
        }

        DialogHelper.showSuccess(context, "Lập hóa đơn thành công!", onTap: () => Navigator.pop(context, true));
      } else {
        DialogHelper.showError(context, res['message']);
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối: $e");
    } finally {
      setLoading(false);
    }
  }
}
