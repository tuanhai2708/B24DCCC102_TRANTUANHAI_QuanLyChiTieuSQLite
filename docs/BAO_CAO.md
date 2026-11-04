
| Nội dung | Ảnh cần chụp | Mô tả gắn với mã nguồn |
| --- | --- | --- |
| Cơ sở dữ liệu | Database Inspector hiển thị users, expenses | Schema và seed trong `_onCreate`, phương thức DatabaseHelper; xem SQL.md |
| Đăng nhập | Sai tài khoản, bỏ trống và thành công | Form validator, mật khẩu ẩn, `checkLogin` SELECT có tham số, pushReplacement |
| Danh sách | Ban đầu, tìm tên, lọc nhóm, kết hợp lọc, rỗng | `_filter`, LIKE/WHERE/ORDER BY, `getSummary` cùng transaction và SUM, FutureBuilder |
| Thêm/sửa | Form thêm, form sửa có dữ liệu, báo lỗi số tiền/tên | `expenseId` phân biệt chế độ, `getExpenseById`, validator, giới hạn ngày, INSERT/UPDATE |
| Chi tiết/xóa | Chi tiết, xác nhận Hủy/Xóa, danh sách sau xóa | Truyền id, SELECT theo id, showDialog, DELETE, reload sau pop |
| Thống kê | Tổng, đủ 5 danh mục và tỷ lệ | GROUP BY, bù nhóm 0, tính phần trăm và LinearProgressIndicator |
| Lưu trữ bền vững | Danh sách sau khi force-stop rồi mở lại | SQLite ghi tệp private, onCreate chỉ chạy lần đầu; khác danh sách RAM |

