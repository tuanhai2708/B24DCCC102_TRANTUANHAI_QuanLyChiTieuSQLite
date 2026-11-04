import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_chi_tieu/data/database_helper.dart';
import 'package:quan_ly_chi_tieu/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late DatabaseHelper db;
  setUp(
    () => db = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    ),
  );
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<void> boot(WidgetTester tester) async {
    await db.database;
    await tester.pumpWidget(ExpenseApp(database: db));
    await settle(tester);
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await settle(tester);
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    ScaffoldMessenger.of(tester.element(target)).hideCurrentSnackBar();
    await settle(tester);
    await tester.ensureVisible(target);
    await settle(tester);
  }

  testWidgets('Đăng nhập chặn trống và sai; tìm kiếm cập nhật tổng/rỗng', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await boot(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await settle(tester);
      expect(find.text('Nhập tên đăng nhập.'), findsOneWidget);
      expect(find.text('Nhập mật khẩu.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'sai');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await settle(tester);
      expect(
        find.text('Tên đăng nhập hoặc mật khẩu không đúng.'),
        findsOneWidget,
      );
      await login(tester);
      expect(find.text('200.000 đ'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ăn sáng');
      await settle(tester);
      expect(find.text('30.000 đ'), findsWidgets);
      expect(find.text('1 khoản chi phù hợp'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await settle(tester);
      expect(find.text('Chưa có khoản chi nào'), findsOneWidget);
      expect(find.text('0 đ'), findsOneWidget);
    });
  });

  testWidgets(
    'Luồng thêm → chi tiết → sửa → hủy xóa → xác nhận xóa → thống kê',
    (tester) async {
      await tester.runAsync(() async {
        await boot(tester);
        await login(tester);
        await tester.tap(find.text('Thêm khoản chi'));
        await settle(tester);
        await scrollTo(tester, find.text('Lưu khoản chi'));
        await tester.tap(find.text('Lưu khoản chi'));
        await settle(tester);
        expect(find.text('Nhập tên khoản chi.'), findsOneWidget);
        expect(find.text('Nhập số tiền nguyên lớn hơn 0.'), findsOneWidget);
        await scrollTo(tester, find.byType(TextFormField).at(0));
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Bữa trưa kiểm thử',
        );
        await tester.enterText(find.byType(TextFormField).at(1), '45000');
        await scrollTo(tester, find.text('Lưu khoản chi'));
        await tester.tap(find.text('Lưu khoản chi'));
        await settle(tester);
        expect(find.text('245.000 đ'), findsOneWidget);
        await scrollTo(tester, find.text('Bữa trưa kiểm thử'));
        await tester.tap(find.text('Bữa trưa kiểm thử'));
        await settle(tester);
        expect(find.text('45.000 đ'), findsOneWidget);
        await scrollTo(tester, find.text('Sửa khoản chi'));
        await tester.tap(find.text('Sửa khoản chi'));
        await settle(tester);
        expect(find.text('Bữa trưa kiểm thử'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).at(1), '55000');
        await scrollTo(tester, find.text('Cập nhật khoản chi'));
        await tester.tap(find.text('Cập nhật khoản chi'));
        await settle(tester);
        expect(find.text('55.000 đ'), findsOneWidget);
        await scrollTo(tester, find.text('Xóa khoản chi'));
        await tester.tap(find.text('Xóa khoản chi'));
        await settle(tester);
        await tester.tap(find.text('Hủy'));
        await settle(tester);
        expect(find.text('Chi tiết khoản chi'), findsOneWidget);
        await tester.tap(find.text('Xóa khoản chi'));
        await settle(tester);
        await tester.tap(find.text('Xóa'));
        await settle(tester);
        expect(find.text('200.000 đ'), findsOneWidget);
        await tester.tap(find.byTooltip('Thống kê'));
        await settle(tester);
        expect(find.text('Thống kê'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Khác'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await settle(tester);
        expect(find.text('Giải trí'), findsOneWidget);
        expect(find.text('Khác'), findsOneWidget);
        expect(find.text('0%'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('Màn hình 320px và cỡ chữ 150% không tràn', (tester) async {
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(tester);
      await scrollTo(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
      expect(tester.takeException(), isNull);
      await login(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Thống kê'));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
