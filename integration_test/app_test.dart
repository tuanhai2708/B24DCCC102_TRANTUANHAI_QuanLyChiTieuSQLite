import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:quan_ly_chi_tieu/data/database_helper.dart';
import 'package:quan_ly_chi_tieu/main.dart';
import 'package:quan_ly_chi_tieu/models/expense.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SQLite native, năm màn hình và lưu lại khi mở kết nối mới', (
    tester,
  ) async {
    final root = await getDatabasesPath();
    // Database riêng cho kiểm thử, không chạm dữ liệu của ứng dụng chính.
    final location = path.join(root, 'integration_expense_manager.db');
    await deleteDatabase(location);
    var db = DatabaseHelper(databasePath: location);
    final screenshots = Directory(path.join(root, 'test_screenshots'));
    await screenshots.create(recursive: true);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final bytes = await binding.takeScreenshot(name);
      await File(path.join(screenshots.path, '$name.png')).writeAsBytes(bytes);
    }

    Future<void> reveal(Finder finder) async {
      ScaffoldMessenger.of(tester.element(finder)).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    Future<void> login() async {
      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pumpAndSettle();
      await reveal(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
    }

    try {
      await db.database;
      await tester.pumpWidget(ExpenseApp(database: db));
      await tester.pumpAndSettle();
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
      }
      await capture('01_dang_nhap');
      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'sai');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tên đăng nhập hoặc mật khẩu không đúng.'),
        findsOneWidget,
      );
      await capture('02_dang_nhap_sai');
      await login();
      expect(find.text('200.000 đ'), findsOneWidget);
      await capture('03_danh_sach');

      await tester.enterText(find.byType(TextField), 'Ăn sáng');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pumpAndSettle();
      expect(find.text('1 khoản chi phù hợp'), findsOneWidget);
      await capture('04_tim_kiem');
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Học tập').last);
      await tester.pumpAndSettle();
      expect(find.text('1 khoản chi phù hợp'), findsOneWidget);
      await capture('05_loc_danh_muc');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả danh mục').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm khoản chi'));
      await tester.pumpAndSettle();
      await capture('06_them');
      await reveal(find.text('Lưu khoản chi'));
      await tester.tap(find.text('Lưu khoản chi'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập số tiền nguyên lớn hơn 0.'), findsOneWidget);
      await reveal(find.byType(TextFormField).first);
      await capture('07_loi_form');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Bữa trưa ở trường',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '45000');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pumpAndSettle();
      await reveal(find.text('Lưu khoản chi'));
      await tester.tap(find.text('Lưu khoản chi'));
      await tester.pumpAndSettle();
      expect(find.text('245.000 đ'), findsOneWidget);
      await reveal(find.text('Bữa trưa ở trường'));
      await tester.tap(find.text('Bữa trưa ở trường'));
      await tester.pumpAndSettle();
      await capture('08_chi_tiet');
      await reveal(find.text('Sửa khoản chi'));
      await tester.tap(find.text('Sửa khoản chi'));
      await tester.pumpAndSettle();
      expect(find.text('Bữa trưa ở trường'), findsOneWidget);
      await capture('09_sua');
      await tester.enterText(find.byType(TextFormField).at(1), '55000');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pumpAndSettle();
      await reveal(find.text('Cập nhật khoản chi'));
      await tester.tap(find.text('Cập nhật khoản chi'));
      await tester.pumpAndSettle();
      expect(find.text('55.000 đ'), findsOneWidget);
      await reveal(find.text('Xóa khoản chi'));
      await tester.tap(find.text('Xóa khoản chi'));
      await tester.pumpAndSettle();
      await capture('10_xac_nhan_xoa');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa khoản chi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('200.000 đ'), findsOneWidget);
      await capture('11_sau_khi_xoa');
      await tester.tap(find.byTooltip('Thống kê'));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      await capture('12_thong_ke');
      await tester.scrollUntilVisible(
        find.text('Khác'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Khác'), findsOneWidget);
      await capture('12b_thong_ke_cuoi');

      // Lưu tệp thật trên Android, đóng/mở kết nối và khởi tạo lại widget tree.
      final id = await db.insertExpense(
        Expense(
          name: 'Lưu sau khi mở lại',
          amount: 10000,
          category: 'Khác',
          date: dateOnly(DateTime.now()),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
      db = DatabaseHelper(databasePath: location);
      expect((await db.getExpenseById(id))!.amount, 10000);
      await tester.pumpWidget(ExpenseApp(database: db));
      await tester.pumpAndSettle();
      await login();
      expect(find.text('210.000 đ'), findsOneWidget);
      await capture('13_mo_lai_ket_noi');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
      await deleteDatabase(location);
    }
  });
}
