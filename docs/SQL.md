# SQL của ứng dụng

Mã nguồn: `lib/data/database_helper.dart`. Database `expense_manager.db`, version 1. `?` được gán tham số qua sqflite; không thay bằng phép nối chuỗi dữ liệu nhập.

## `_onCreate()` — tạo bảng

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
);
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK(amount > 0),
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  note TEXT
);
```

`id` tự tăng; tên đăng nhập duy nhất; tiền phải dương. Ngày ISO `yyyy-MM-dd` cho phép sắp xếp đúng theo thời gian. Kiểm tra danh mục/ngày/tên còn được thực hiện trong `Expense.validate()` và form.

## `_onCreate()` — dữ liệu khởi tạo

Mã dùng tham số/batch; dưới đây là SQL tương đương với giá trị mẫu đầy đủ:

```sql
INSERT INTO users (username, password) VALUES ('admin', '123456');
INSERT INTO expenses (name, amount, category, date)
VALUES ('Ăn sáng', 30000, 'Ăn uống', '2026-10-13');
INSERT INTO expenses (name, amount, category, date)
VALUES ('Đổ xăng', 50000, 'Đi lại', '2026-10-12');
INSERT INTO expenses (name, amount, category, date)
VALUES ('Mua sách', 120000, 'Học tập', '2026-10-11');
```

Chỉ chạy khi tạo database. Callback onCreate của sqflite đã nằm trong transaction; lỗi tạo/seed được rollback.

## `checkLogin(username, password)`

```sql
SELECT id FROM users
WHERE username = ? AND password = ?
LIMIT 1;
```

Tham số: tên đã trim và mật khẩu. Có kết quả là đúng tài khoản. Không cho đăng nhập với trường trống.

## `insertExpense(expense)`

```sql
INSERT INTO expenses (name, amount, category, date, note)
VALUES (?, ?, ?, ?, ?);
```

Tương đương `db.insert('expenses', expense.toMap())`. Trả về id được tạo, ném lỗi nếu không lưu được; UI bắt lỗi và cho thử lại.

## `getExpenseById(id)`

```sql
SELECT * FROM expenses WHERE id = ? LIMIT 1;
```

Tương đương `query` có `whereArgs`. Trả về Expense hoặc null khi id không tồn tại.

## `getExpenses(keyword, category)` và `getSummary()`

Khi có danh mục:

```sql
SELECT * FROM expenses
WHERE name LIKE ? ESCAPE '\' AND category = ?
ORDER BY date DESC, id DESC;
```

Khi chọn Tất cả danh mục:

```sql
SELECT * FROM expenses
WHERE name LIKE ? ESCAPE '\'
ORDER BY date DESC, id DESC;
```

Tham số đầu: `%từ khóa%` sau khi escape `\`, `%`, `_`; tham số thứ hai là danh mục. Từ khóa rỗng dùng `%%`. Tìm tên và lọc kết hợp. Ngày mới trước, cùng ngày thì id mới trước. `_filter()` chỉ ghép cấu trúc SQL cố định; các giá trị đều qua tham số.

## `getTotal(keyword, category)` và `getSummary()`

```sql
SELECT COALESCE(SUM(amount), 0) AS total
FROM expenses
WHERE name LIKE ? ESCAPE '\' AND category = ?;
```

Bỏ `AND category = ?` khi chọn tất cả. Dùng **cùng điều kiện và tham số** như danh sách. `COALESCE` trả 0 thay cho NULL khi không có kết quả. `getSummary()` chạy truy vấn danh sách và SUM trong cùng transaction để đồng nhất dữ liệu.

## `getTotalByCategory()`

```sql
SELECT category, SUM(amount) AS total
FROM expenses
GROUP BY category;
```

Gộp tiền theo danh mục. Dart bổ sung các danh mục không có dữ liệu với tổng 0 để luôn hiển thị đủ 5 nhóm. Tổng chung là tổng các nhóm; phần trăm `tổng nhóm / tổng chung * 100`. Nếu tổng bằng 0 thì tất cả tỷ lệ là 0, không chia cho 0.

## `updateExpense(expense)`

```sql
UPDATE expenses
SET name = ?, amount = ?, category = ?, date = ?, note = ?
WHERE id = ?;
```

Tương đương `db.update` với map, `where: 'id = ?'`, `whereArgs: [expense.id]`. Trả về số dòng bị thay đổi. Form kiểm tra kết quả bằng 0 để báo không lưu được.

## `deleteExpense(id)`

```sql
DELETE FROM expenses WHERE id = ?;
```

Tương đương `db.delete` có tham số. UI chỉ gọi sau khi xác nhận Xóa; quay về danh sách và truy vấn lại tổng/danh sách.
