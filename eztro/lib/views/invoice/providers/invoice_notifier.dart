import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/invoice_model.dart';
import '../../../services/invoice_service.dart';

part 'invoice_notifier.g.dart';

@riverpod
class InvoiceNotifier extends _$InvoiceNotifier {
  @override
  Future<List<InvoiceModel>> build() async {
    return _fetchData();
  }

  Future<List<InvoiceModel>> _fetchData() async {
    // Luôn lấy tất cả hóa đơn ban đầu, việc lọc sẽ do FilterProvider đảm nhận
    return await InvoiceService.getInvoices();
  }

  // Làm mới danh sách
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  // Cập nhật trạng thái thanh toán (Thanh toán cục bộ sau đó refresh)
  Future<Map<String, dynamic>> updateStatus(dynamic invoiceId, String status, {String reason = ""}) async {
    final res = await InvoiceService.updateInvoiceStatus(invoiceId, status, reason: reason);
    if (res['status'] == 'success') {
      await refresh();
    }
    return res;
  }

  // Xóa hóa đơn
  Future<Map<String, dynamic>> deleteInvoice(dynamic invoiceId) async {
    final res = await InvoiceService.deleteInvoice(invoiceId);
    if (res['status'] == 'success') {
      await refresh();
    }
    return res;
  }
}
