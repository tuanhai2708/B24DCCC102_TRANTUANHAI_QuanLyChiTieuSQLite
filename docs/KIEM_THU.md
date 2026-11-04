# Kết quả kiểm thử ngày 04/11/2026

Môi trường: Flutter 3.47.9, Dart 3.13.7; emulator Android arm64, API 37.1. Ứng dụng Android compile/target SDK 36, min SDK 24.

- `flutter analyze`: không có vấn đề.
- `flutter test`: 11/11 kiểm thử đạt (8 SQLite và 3 giao diện).
- `flutter test integration_test/app_test.dart -d emulator-5554`: luồng SQLite native đạt.
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554`: đạt, lưu 14 PNG trong `screenshots/`.
- `flutter build apk --debug`: xuất APK thường bằng `lib/main.dart` sau khi kiểm thử.

Phạm vi: đăng nhập trống/sai/đúng và truy vấn bảng users; thêm/đọc/sửa/xóa; tìm theo tên kết hợp lọc; xử lý LIKE và dữ liệu SQL đặc biệt; tổng và sắp xếp; GROUP BY và danh mục 0; kiểm tra dữ liệu không hợp lệ; đóng/mở lại tệp SQLite giữ nguyên thêm/sửa/xóa. Giao diện được kiểm tra với màn hình 320 px, cỡ chữ 150%; luồng Android thực đi qua năm màn hình và xác nhận xóa có Hủy.

Đã bổ sung force-stop tiến trình Android thật: pidof sau am force-stop không còn tiến trình; mở lại MainActivity và đăng nhập vẫn có khoản Kiem tra luu tru 10.000 đ, tổng 210.000 đ. Ảnh nằm ở report_assets/16_truoc_force_stop.png và 17_sau_force_stop.png. Dữ liệu hai bảng được trích thực qua ADB/sqlite3; chưa có ảnh Database Inspector. Chưa xác minh build iOS/macOS vì máy không có Xcode.
