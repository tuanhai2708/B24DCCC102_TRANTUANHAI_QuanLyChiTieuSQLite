# Định hướng thiết kế

Sổ chi tiêu cá nhân dành cho sinh viên: ghi nhanh một khoản chi, tìm lại và biết tiền đã đi đâu. Flutter native, giao diện tiếng Việt, lưu SQLite trên thiết bị.

## Hệ thống thiết kế

- Màu: trắng `#FFFFFF`, nền `#F3F7FC`, chữ mực `#182D49`, thao tác xanh lam `#245BCC`, chữ phụ `#5C6F88`, ranh giới `#DFE7F2`.
- Be Vietnam Pro đóng gói để dấu tiếng Việt đồng nhất, không cần mạng. Cỡ 14/16 nội dung, 20/26 tiêu đề, 36 tổng tiền. Trọng lượng 400/600. Căn trái, nội dung tối đa 760 px.
- Điểm nhấn: tổng chi nền xanh lam; dòng khoản chi phẳng, biểu tượng danh mục. Không cần thẻ bóng đổ.
- Danh mục có màu, chữ và biểu tượng nhất quán giữa danh sách, chi tiết, thống kê.

## Bố cục chọn trước khi xây dựng

Danh sách dọc với tìm kiếm/lọc ở trên và nút thêm cố định cuối màn hình dành diện tích cho các khoản chi trên điện thoại.

```text
Sổ chi tiêu                   Thống kê / Đăng xuất
[ Tổng chi theo bộ lọc                            ]
[ Tìm tên khoản chi                               ]
[ Tất cả danh mục                               v ]
Các khoản chi
biểu tượng   Tên khoản chi                  Số tiền
             Danh mục, ngày
                                    [Thêm khoản chi]
```


## Rà soát ảnh Android

Đã xem ảnh danh sách, form báo lỗi và thống kê trên emulator 1080 × 2400. Font hiển thị đủ dấu tiếng Việt, số tiền nổi bật và không tràn. Sửa dải tỷ trọng tổng hợp: Row phải kéo các khối màu đủ chiều cao, tránh vùng trống dù số liệu đúng. Thay câu dẫn trang trí trên form bằng hướng dẫn tên/số tiền bắt buộc; ẩn thông báo cũ khi mở màn khác để không che nội dung thống kê. Kiểm thử bố cục thêm màn rộng 320 px, cỡ chữ 150%.
