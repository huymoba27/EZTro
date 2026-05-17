import 'package:intl/intl.dart';

/// Tiện ích format tiền tệ Việt Nam.
/// Sử dụng: `CurrencyHelper.formatVND(3500000)` → "3.500.000 đ"
class CurrencyHelper {
  static final _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  /// Format số tiền sang chuỗi VNĐ (VD: 3.500.000 đ)
  static String formatVND(dynamic amount) {
    if (amount == null) return "0 đ";
    final value = double.tryParse(amount.toString()) ?? 0;
    return _formatter.format(value);
  }

  /// Format số tiền sang chuỗi rút gọn (VD: 3.5tr, 500k)
  static String formatShort(dynamic amount) {
    if (amount == null) return "0 đ";
    final value = double.tryParse(amount.toString()) ?? 0;
    if (value >= 1000000) {
      final tr = value / 1000000;
      return "${tr.toStringAsFixed(tr.truncateToDouble() == tr ? 0 : 1)}tr";
    } else if (value >= 1000) {
      final k = value / 1000;
      return "${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 0)}k";
    }
    return _formatter.format(value);
  }
}

/// Tiện ích xử lý chuỗi.
class StringHelper {
  /// Chuyển đổi chuỗi thành Title Case (Viết hoa chữ cái đầu mỗi từ)
  /// Ví dụ: "nguyễn văn a" -> "Nguyễn Văn A"
  static String capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
