# EzTro - Ứng dụng quản lý nhà trọ

EzTro là hệ thống quản lý nhà trọ dành cho chủ trọ, quản lý và khách thuê. Dự án gồm backend API viết bằng PHP/MySQL và ứng dụng client viết bằng Flutter.

Ứng dụng hỗ trợ các nghiệp vụ chính khi vận hành nhà trọ: quản lý nhà, phòng, khách thuê, hợp đồng, chỉ số điện nước, hóa đơn, đặt cọc, phiếu thu, chi phí, sự cố, bài đăng cho thuê, chat, thông báo, thanh toán PayOS, bản đồ Mapbox và trợ lý AI dùng Gemini.

## Trạng thái dự án

Repo này phù hợp để dùng làm portfolio, đồ án hoặc dự án học tập. Backend hiện chưa nên xem là hệ thống production-ready.

Trước khi triển khai công khai, nên rà soát kỹ các phần: xác thực, phân quyền, an toàn truy vấn SQL, CORS, kiểm tra file upload và quản lý secret/API key.

## Công nghệ sử dụng

- Backend: PHP, MySQL, Composer
- Ứng dụng: Flutter, Dart, Riverpod
- Thanh toán: PayOS
- Bản đồ: Mapbox
- AI assistant: Google Gemini API
- Môi trường phát triển local: XAMPP

## Cấu trúc thư mục

```text
.
|-- backend_api/          # Các endpoint PHP API
|-- config/               # File cấu hình mẫu và cấu hình local
|-- docs/                 # Tài liệu dự án
|-- eztro/                # Ứng dụng Flutter
|-- uploads/              # File upload khi chạy app, không commit lên Git
|-- .env.example          # File môi trường mẫu cho backend
`-- composer.json         # Dependency PHP
```

## Tính năng chính

- Đăng ký, đăng nhập cho chủ trọ, quản lý và khách thuê
- Quản lý nhà trọ, phòng, khách thuê và hợp đồng
- Theo dõi trạng thái phòng: trống, đã cọc, đang thuê, đầy, ngừng hoạt động
- Ghi chỉ số điện nước và tạo hóa đơn hằng tháng
- Quản lý phiếu thu và chi phí
- Quy trình đặt cọc và tạo link thanh toán PayOS
- Khách thuê báo sự cố
- Đăng bài cho thuê và lưu tin yêu thích
- Chat giữa người dùng
- Thông báo trong hệ thống
- Thống kê doanh thu, chi phí và tình trạng vận hành
- Chọn và hiển thị vị trí bằng Mapbox
- Trợ lý AI hỗ trợ nghiệp vụ cho chủ trọ và khách thuê

## Yêu cầu môi trường

- PHP 8.x
- Composer
- MySQL hoặc MariaDB
- XAMPP hoặc web server PHP/MySQL tương đương
- Flutter SDK 3.11.4 trở lên
- Android Studio, Xcode hoặc Chrome tùy nền tảng chạy app

## Cài đặt backend

1. Clone repo vào web root. Với XAMPP, đường dẫn local mặc định là:

   ```bash
   C:/xampp/htdocs/ql_tro
   ```

2. Cài dependency PHP:

   ```bash
   composer install
   ```

3. Tạo file môi trường cho backend:

   ```bash
   cp .env.example .env
   ```

4. Cập nhật thông tin trong `.env`:

   ```env
   DB_HOST=localhost
   DB_USER=root
   DB_PASS=
   DB_NAME=ql_tro

   PUBLIC_BASE_URL=http://localhost/ql_tro

   PAYOS_CLIENT_ID=YOUR_PAYOS_CLIENT_ID
   PAYOS_API_KEY=YOUR_PAYOS_API_KEY
   PAYOS_CHECKSUM_KEY=YOUR_PAYOS_CHECKSUM_KEY
   ```

5. Tạo file cấu hình local từ file mẫu:

   ```bash
   cp config/config.example.php config/config.php
   cp config/payment_config.example.php config/payment_config.php
   ```

6. Tạo database MySQL tên `ql_tro`.

   Repo hiện chưa kèm file schema/export database public. Hãy import schema local của bạn trước khi chạy ứng dụng.

7. Khởi động Apache và MySQL, sau đó kiểm tra API tại:

   ```text
   http://localhost/ql_tro/backend_api
   ```

## Cài đặt ứng dụng Flutter

1. Chuyển vào thư mục app:

   ```bash
   cd eztro
   ```

2. Cài dependency Flutter:

   ```bash
   flutter pub get
   ```

3. Tạo file môi trường cho Flutter:

   ```bash
   cp .env.example .env
   ```

4. Cập nhật `eztro/.env`:

   ```env
   MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY
   SERVER_URL=http://localhost/ql_tro
   ```

   Nếu chạy trên điện thoại thật, `localhost` sẽ trỏ tới chính điện thoại. Khi đó hãy đổi `SERVER_URL` thành IP LAN của máy tính hoặc URL tunnel như ngrok.

5. Tạo file secret cho Mapbox từ file mẫu:

   ```bash
   cp lib/core/constants/app_secrets.example.dart lib/core/constants/app_secrets.dart
   ```

6. Chạy ứng dụng:

   ```bash
   flutter run
   ```

## Ghi chú về PayOS

Thông tin PayOS được đọc từ file `.env` của backend. Khi test local, cần cấu hình:

- `PUBLIC_BASE_URL`
- `PAYOS_CLIENT_ID`
- `PAYOS_API_KEY`
- `PAYOS_CHECKSUM_KEY`

Nếu dùng ngrok hoặc tunnel khác, hãy đặt `PUBLIC_BASE_URL` và `SERVER_URL` trong `eztro/.env` theo URL public của tunnel.

## Ghi chú về AI và bản đồ

- Gemini API key được đọc từ `eztro/.env`.
- Mapbox token được đọc qua `AppSecrets.mapboxAccessToken`.
- Không commit API key thật. Chỉ dùng các file `.example` làm mẫu.

## An toàn khi public repo

Các file và thư mục sau đã được đưa vào `.gitignore`:

- `.env` và các file môi trường local
- `config/config.php` và `config/payment_config.php`
- `uploads/` và file người dùng upload
- key ký app mobile và file secret nền tảng
- build output của Flutter
- script auto test local chưa ổn định trong `tools/auto_tests/`
- tài liệu cá nhân trong `docs/private/`

Trước khi push public, hãy kiểm tra lại Git history nếu trước đây từng commit nhầm credential hoặc dữ liệu cá nhân.

## Dev Autofill

Ứng dụng có phần dữ liệu mẫu và nút autofill hỗ trợ nhập nhanh khi demo hoặc test thủ công. Phần này hữu ích khi trình bày luồng nghiệp vụ, nhưng không nên dùng thay cho test tự động chính thức.

## Giới hạn hiện tại

- Chưa có file schema database public đi kèm.
- Backend hiện còn phụ thuộc nhiều vào `user_id` gửi từ client; trước khi production nên thay bằng session hoặc token đã ký.
- Một số endpoint vẫn dùng SQL ghép chuỗi trực tiếp và cần tiếp tục chuyển sang prepared statement.
- CORS đang mở rộng để tiện phát triển local.
- Luồng upload file cần được siết chặt hơn trước khi triển khai thật.

## License

Dự án hiện chưa khai báo license. Nên thêm file `LICENSE` trước khi cho phép người khác sử dụng lại hoặc đóng góp.
