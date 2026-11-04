import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_chi_tieu/data/database_helper.dart';
import 'package:quan_ly_chi_tieu/models/expense.dart';
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

  Expense sample({
    String name = 'Bữa trưa',
    int amount = 45000,
    String category = 'Ăn uống',
    DateTime? date,
    int? id,
  }) => Expense(
    id: id,
    name: name,
    amount: amount,
    category: category,
    date: date ?? DateTime(2026, 10, 10),
    note: 'Có ghi chú',
  );

  test('Khởi tạo đúng mẫu và chỉ đăng nhập bằng dữ liệu trong users', () async {
    expect(await db.checkLogin('admin', '123456'), isTrue);
    expect(await db.checkLogin('admin', 'wrong'), isFalse);
    expect(await db.checkLogin('', ''), isFalse);
    expect(await db.checkLogin("admin' OR 1=1 --", 'bad'), isFalse);
    expect(await db.getTotal(), 200000);
    expect((await db.getExpenses()).map((e) => e.name), [
      'Ăn sáng',
      'Đổ xăng',
      'Mua sách',
    ]);
    await (await db.database).update(
      'users',
      {'password': 'new'},
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    expect(await db.checkLogin('admin', '123456'), isFalse);
    expect(await db.checkLogin('admin', 'new'), isTrue);
  });

  test('Thêm, truy vấn theo id, sửa và xóa; cập nhật tổng', () async {
    final id = await db.insertExpense(sample());
    expect(id, greaterThan(0));
    expect((await db.getExpenseById(id))!.note, 'Có ghi chú');
    expect(await db.getTotal(), 245000);
    expect(
      await db.updateExpense(
        sample(id: id, name: 'Vé xe', amount: 7000, category: 'Đi lại'),
      ),
      1,
    );
    expect((await db.getExpenseById(id))!.name, 'Vé xe');
    expect(await db.getTotal(category: 'Đi lại'), 57000);
    expect(await db.deleteExpense(id), 1);
    expect(await db.getExpenseById(id), isNull);
    expect(await db.getTotal(), 200000);
    expect(await db.updateExpense(sample(id: id)), 0);
  });

  test('Tìm kiếm và lọc kết hợp, danh sách và tổng cùng điều kiện', () async {
    await db.insertExpense(sample(name: 'Ăn tối', amount: 40000));
    await db.insertExpense(
      sample(name: 'Ăn ở rạp', amount: 60000, category: 'Giải trí'),
    );
    final result = await db.getSummary(keyword: 'Ăn', category: 'Ăn uống');
    expect(result.expenses.map((e) => e.name), ['Ăn sáng', 'Ăn tối']);
    expect(result.total, 70000);
    expect(await db.getTotal(keyword: 'Ăn', category: 'Ăn uống'), result.total);
    expect((await db.getExpenses(category: 'Tất cả danh mục')).length, 5);
    expect((await db.getSummary(keyword: 'không tồn tại')).expenses, isEmpty);
    expect(await db.getTotal(keyword: 'không tồn tại'), 0);
  });

  test('LIKE coi %, _, dấu nháy và dấu gạch chéo là dữ liệu', () async {
    for (final name in ['Giảm 50%', 'A_B', r'C:\temp', "O'Brien"]) {
      await db.insertExpense(sample(name: name));
    }
    for (final keyword in ['%', '_', r'\', "O'Brien"]) {
      expect(await db.getExpenses(keyword: keyword), hasLength(1));
    }
    expect(await db.getExpenses(keyword: "' OR 1=1 --"), isEmpty);
  });

  test('Ngày mới trước, cùng ngày thì id lớn trước', () async {
    final a = await db.insertExpense(
      sample(name: 'Một', date: DateTime(2026, 10, 14)),
    );
    final b = await db.insertExpense(
      sample(name: 'Hai', date: DateTime(2026, 10, 14)),
    );
    final expenses = await db.getExpenses();
    expect(expenses.take(2).map((e) => e.id), [b, a]);
    expect(expenses.first.toMap()['date'], '2026-10-14');
  });

  test('GROUP BY đủ 5 danh mục, có cả nhóm 0 đồng', () async {
    final totals = await db.getTotalByCategory();
    expect(totals, {
      'Ăn uống': 30000,
      'Đi lại': 50000,
      'Học tập': 120000,
      'Giải trí': 0,
      'Khác': 0,
    });
    for (final expense in await db.getExpenses()) {
      await db.deleteExpense(expense.id!);
    }
    expect((await db.getTotalByCategory()).values, everyElement(0));
    expect(await db.getTotal(), 0);
  });

  test('Chặn dữ liệu không hợp lệ ở cả lớp lưu trữ', () async {
    for (final invalid in [
      sample(name: ' '),
      sample(amount: 0),
      sample(amount: -1),
      sample(category: 'Sai'),
      sample(date: DateTime.now().add(const Duration(days: 1))),
      sample(amount: 1000000000000000),
    ]) {
      await expectLater(db.insertExpense(invalid), throwsArgumentError);
    }
    expect(await db.getTotal(), 200000);
  });

  test(
    'Đóng và mở lại tệp giữ nguyên thêm/sửa/xóa, không seed lần hai',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'th411-persistence-',
      );
      final location = '${directory.path}/expense_manager.db';
      var diskDb = DatabaseHelper(
        factory: databaseFactoryFfi,
        databasePath: location,
      );
      try {
        final initial = await diskDb.getExpenses();
        await diskDb.deleteExpense(initial.first.id!);
        await diskDb.updateExpense(
          sample(
            id: initial[1].id,
            name: 'Xăng mới',
            amount: 80000,
            category: 'Đi lại',
          ),
        );
        final addedId = await diskDb.insertExpense(
          sample(name: 'Lưu bền vững'),
        );
        await diskDb.close();
        diskDb = DatabaseHelper(
          factory: databaseFactoryFfi,
          databasePath: location,
        );
        expect(await diskDb.checkLogin('admin', '123456'), isTrue);
        expect(await diskDb.getExpenseById(initial.first.id!), isNull);
        expect((await diskDb.getExpenseById(initial[1].id!))!.amount, 80000);
        expect((await diskDb.getExpenseById(addedId))!.name, 'Lưu bền vững');
        expect(await diskDb.getExpenses(), hasLength(3));
        expect(await diskDb.getTotal(), 245000);
      } finally {
        await diskDb.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
