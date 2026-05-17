class InputValidationHelper {
  static String normalizePhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s\.\-\(\)]'), '');
  }

  static bool isValidVietnamPhone(String value) {
    return RegExp(r'^0[0-9]{9,10}$').hasMatch(normalizePhone(value));
  }

  static String? phoneError(String value) {
    if (value.trim().isEmpty) return "Vui lòng nhập số điện thoại";
    if (!isValidVietnamPhone(value)) {
      return "Số điện thoại phải gồm 10-11 chữ số và bắt đầu bằng 0";
    }
    return null;
  }
}
