# EzTro Flutter App

Thư mục này chứa ứng dụng Flutter client của EzTro.

Để xem hướng dẫn cài đặt đầy đủ cho cả backend, cấu hình môi trường, ghi chú khi public repo và các giới hạn hiện tại, hãy xem [README chính](../README.md).

## Chạy nhanh

```bash
cd eztro
flutter pub get
cp .env.example .env
cp lib/core/constants/app_secrets.example.dart lib/core/constants/app_secrets.dart
flutter run
```

Cập nhật `eztro/.env` trước khi chạy:

```env
MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
SERVER_URL=http://localhost/ql_tro
```

Nếu test trên điện thoại thật, `localhost` sẽ trỏ tới chính điện thoại. Hãy dùng IP LAN của máy tính hoặc URL tunnel cho `SERVER_URL`.
