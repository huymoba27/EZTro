import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ======================================================
  // CẤU HÌNH SERVER - Chỉ cần sửa 1 dòng bên dưới
  // ======================================================
  // Đọc URL từ file .env (Giúp đổi URL ngrok cực nhanh không cần sửa code)
  static String get serverUrl {
    return dotenv.env['SERVER_URL'] ?? "http://localhost/ql_tro";
  }

  static String get baseUrl => "$serverUrl/backend_api";
  static String get baseImageUrl => serverUrl;

  // Đường dẫn các Module cụ thể
  static String get houses => "$baseUrl/houses";
  static String get rooms => "$baseUrl/rooms";
  static String get tenants => "$baseUrl/tenants";
  static String get contracts => "$baseUrl/contracts";
  static String get meters => "$baseUrl/meters";
  static String get services => "$baseUrl/services";
  static String get invoices => "$baseUrl/invoice";
  static String get vehicles => "$baseUrl/vehicle";
  static String get reports => "$baseUrl/reports";
  static String get payment => "$baseUrl/payment";
  static String get notifications => "$baseUrl/notifications";

  // Headers mặc định (ngrok cần header này để bỏ qua trang cảnh báo)
  static Map<String, String> get headers => {
    'ngrok-skip-browser-warning': 'true',
  };
}
