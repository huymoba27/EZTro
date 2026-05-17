/// Tiện ích chuyển đổi loại khoản thu/chi từ tiếng Anh sang tiếng Việt.
/// Sử dụng: `ReceiptTypeHelper.toVietnamese('monthly', isReceipt: true)` → "Tiền phòng"
class ReceiptTypeHelper {
  static const Map<String, String> _mapping = {
    'monthly': 'Tiền phòng',
    'monthly_bill': 'Tiền phòng',
    'utility': 'Tiện ích',
    'deposit': 'Tiền cọc',
    'maintenance': 'Sửa chữa',
    'refund': 'Hoàn tiền',
    'penalty': 'Tiền phạt',
    'electricity': 'Tiền điện',
    'water': 'Tiền nước',
    'wifi': 'Tiền mạng',
    'garbage': 'Tiền rác',
    'parking': 'Tiền xe',
  };

  /// Chuyển loại khoản thu/chi sang tiếng Việt.
  /// [type] - Giá trị gốc từ DB (ví dụ: 'monthly', 'electricity')
  /// [isReceipt] - true nếu là phiếu thu, false nếu là phiếu chi
  static String toVietnamese(String? type, {bool isReceipt = true}) {
    if (type == null || type.isEmpty) {
      return isReceipt ? 'Khoản thu' : 'Khoản chi';
    }

    final lower = type.toLowerCase();
    if (lower == 'other') return isReceipt ? 'Thu khác' : 'Chi khác';
    return _mapping[lower] ?? type;
  }
}
