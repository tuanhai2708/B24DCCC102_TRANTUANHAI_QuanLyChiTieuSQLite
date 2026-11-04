B24DCCC102_TRANTUANHAI_QuanLyChiTieuSQLite

# Sổ chi tiêu — Flutter & SQLite

Bài thực hành số 3: ứng dụng quản lý chi tiêu cá nhân, triển khai bằng Flutter. Các thành phần Java/XML trong đề được thay bằng widget, Navigator và sqflite tương ứng. Dữ liệu lưu cục bộ trong `expense_manager.db`, phiên bản 1; không dùng API, Firebase hay dữ liệu RAM làm nguồn lưu trữ.

## Chạy ứng dụng

Máy đã dùng để phát triển: Flutter 3.47.9 / Dart 3.13.7. Dự án yêu cầu Dart 3.13 trở lên.

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

Chọn máy Android/emulator. Dự án cũng có cấu hình iOS và macOS; cần Xcode cùng công cụ native tương ứng để build. Không chạy trên Chrome vì phiên bản này dùng SQLite native.

Tài khoản được chèn vào bảng `users` **chỉ khi tạo database lần đầu**:

- Tên đăng nhập: `admin`
- Mật khẩu: `123456`

Dữ liệu mẫu: Ăn sáng 30.000 đ (13/10/2026), Đổ xăng 50.000 đ (12/10/2026), Mua sách 120.000 đ (11/10/2026). Tổng ban đầu 200.000 đ.

```sh
flutter analyze
flutter test
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Bản debug phục vụ thực hành, không dùng để phát hành cửa hàng.

## Đủ 5 màn hình

1. **Đăng nhập:** kiểm tra trống, ẩn/hiện mật khẩu, truy vấn tài khoản trong SQLite, báo sai và thay route sau khi đăng nhập thành công.
2. **Danh sách:** tìm theo tên ngay khi gõ, kết hợp lọc 5 danh mục, tổng và số khoản theo bộ lọc, mới nhất trước, kéo để tải lại, trạng thái rỗng và thử lại khi lỗi. Có thêm khoản chi, thống kê và đăng xuất.
3. **Thêm/sửa:** cùng một form, nhận `expenseId` khi sửa rồi truy vấn lại. Tên bắt buộc, tiền nguyên dương tối đa 15 chữ số, danh mục bắt buộc, chọn ngày không vượt hôm nay, ghi chú tùy chọn. Lưu thành công quay về màn trước.
4. **Chi tiết:** nhận id, đọc đầy đủ thông tin, sửa rồi đọc lại; xóa có hộp thoại Hủy/Xóa; quay về danh sách và tải lại.
5. **Thống kê:** SQLite `GROUP BY`, tổng toàn bộ, đủ 5 danh mục (kể cả 0), số tiền, phần trăm, thanh tỷ trọng; xử lý tổng bằng 0.

Tiền hiển thị có phân cách hàng nghìn, ngày `dd/MM/yyyy`; database lưu `yyyy-MM-dd`. Mọi tham số người dùng dùng `?`, không nối chuỗi vào SQL. SQLite LIKE được escape để `%`, `_` và `\` là ký tự tìm kiếm thông thường. LIKE mặc định của SQLite phân biệt chữ hoa/thường ở một số ký tự Unicode, không hỗ trợ tìm bỏ dấu.

## Tổ chức mã

```text
lib/
  main.dart                       Khởi tạo MaterialApp, locale tiếng Việt
  theme.dart                      Font, màu, định dạng tiền/ngày
  models/expense.dart             Expense có id, kiểm tra dữ liệu
  data/database_helper.dart       Schema, seed, CRUD, LIKE/SUM/GROUP BY
  screens/
    login_screen.dart
    home_screen.dart
    edit_screen.dart
    detail_screen.dart
    statistics_screen.dart
  widgets/common.dart             Thành phần giao diện chung
```

`Navigator` truyền **id** thay vì truyền một danh sách chung. Danh sách và tổng được truy vấn cùng một transaction trong `getSummary()`; `getExpenses()` và `getTotal()` cũng có sẵn theo đề. sqflite quản lý Cursor native; ứng dụng nhận danh sách map Dart, không có Cursor cần đóng thủ công. Kết nối dùng chung suốt vòng đời ứng dụng; `close()` phục vụ kiểm thử/mở lại. Bản v1 tạo schema trong `onCreate`; khi thêm migration phải tăng version và bổ sung `onUpgrade`, tránh xóa dữ liệu cũ.

Tệp database được SQLite ghi xuống vùng lưu trữ riêng của ứng dụng. Tắt hẳn rồi mở lại không tạo lại database và không chèn lại mẫu. Gỡ ứng dụng hoặc xóa dữ liệu ứng dụng sẽ xóa database. Đăng xuất chỉ trở về màn đăng nhập.

Mật khẩu lưu nguyên văn đúng phạm vi bài thực hành; không dùng thiết kế tài khoản này cho sản phẩm thực tế.

## Kiểm thử

- `test/database_helper_test.dart`: database SQLite thật qua FFI, đăng nhập, CRUD, tìm/lọc, ký tự đặc biệt và SQL injection, sắp xếp, tổng, 5 danh mục, validation, đóng và mở lại **tệp thật** để xác minh lưu bền vững sau thêm/sửa/xóa.
- `test/widget_test.dart`: kiểm tra đăng nhập trống/sai, tìm kiếm/tổng/rỗng, thêm/sửa/xóa có hủy xác nhận, thống kê và màn hình nhỏ với chữ phóng lớn.

## Tài liệu và nộp bài

- [Các câu SQL và giải thích theo phương thức](docs/SQL.md).
- [Thiết kế giao diện](docs/THIET_KE.md).
- [Danh sách ảnh và nội dung báo cáo](docs/BAO_CAO.md).

Tài liệu SQLite Flutter chính thức: https://docs.flutter.dev/cookbook/persistence/sqlite

