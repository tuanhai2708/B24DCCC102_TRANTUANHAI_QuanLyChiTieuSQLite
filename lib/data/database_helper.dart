import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

/// Màn hình đọc lại qua lớp này; không dùng danh sách chung làm nguồn dữ liệu.
class DatabaseHelper {
  DatabaseHelper({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;
  static final instance = DatabaseHelper();
  static const databaseName = 'expense_manager.db';
  final DatabaseFactory _factory;
  final String? databasePath;
  Future<Database>? _opening;

  Future<Database> get database async {
    try {
      return await (_opening ??= _open());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final location =
        databasePath ??
        path.join(await _factory.getDatabasesPath(), databaseName);
    return _factory.openDatabase(
      location,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK(amount > 0),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.rawInsert('INSERT INTO users (username, password) VALUES (?, ?)', [
      'admin',
      '123456',
    ]);
    final batch = db.batch();
    for (final row in [
      ['Ăn sáng', 30000, 'Ăn uống', '2026-10-13'],
      ['Đổ xăng', 50000, 'Đi lại', '2026-10-12'],
      ['Mua sách', 120000, 'Học tập', '2026-10-11'],
    ]) {
      batch.rawInsert(
        'INSERT INTO expenses (name, amount, category, date) VALUES (?, ?, ?, ?)',
        row,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<bool> checkLogin(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) return false;
    final rows = await (await database).rawQuery(
      'SELECT id FROM users WHERE username = ? AND password = ? LIMIT 1',
      [username.trim(), password],
    );
    return rows.isNotEmpty;
  }

  Future<int> insertExpense(Expense expense) async {
    expense.validate();
    return (await database).insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    expense.validate();
    if (expense.id == null) throw ArgumentError('Thiếu mã khoản chi.');
    return (await database).update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async =>
      (await database).delete('expenses', where: 'id = ?', whereArgs: [id]);

  Future<Expense?> getExpenseById(int id) async {
    final rows = await (await database).query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  /// Tìm ký tự LIKE theo nghĩa đen; toàn bộ dữ liệu nhập dùng tham số SQL.
  (String, List<Object?>) _filter(String keyword, String? category) {
    final escaped = keyword
        .trim()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    var where = "name LIKE ? ESCAPE '\\'";
    final args = <Object?>['%$escaped%'];
    if (category != null && category != 'Tất cả danh mục') {
      where += ' AND category = ?';
      args.add(category);
    }
    return (where, args);
  }

  Future<List<Expense>> getExpenses({
    String keyword = '',
    String? category,
  }) async {
    final (where, args) = _filter(keyword, category);
    final rows = await (await database).rawQuery(
      'SELECT * FROM expenses WHERE $where ORDER BY date DESC, id DESC',
      args,
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> getTotal({String keyword = '', String? category}) async {
    final (where, args) = _filter(keyword, category);
    final rows = await (await database).rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE $where',
      args,
    );
    return rows.first['total'] as int;
  }

  /// Tổng và danh sách được truy vấn trong cùng một transaction.
  Future<ExpenseSummary> getSummary({
    String keyword = '',
    String? category,
  }) async {
    final (where, args) = _filter(keyword, category);
    return (await database).transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT * FROM expenses WHERE $where ORDER BY date DESC, id DESC',
        args,
      );
      final totals = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE $where',
        args,
      );
      return ExpenseSummary(
        rows.map(Expense.fromMap).toList(),
        totals.first['total'] as int,
      );
    });
  }

  Future<Map<String, int>> getTotalByCategory() async {
    final rows = await (await database).rawQuery(
      'SELECT category, SUM(amount) AS total FROM expenses GROUP BY category',
    );
    return {
      for (final category in expenseCategories) category: 0,
      for (final row in rows) row['category'] as String: row['total'] as int,
    };
  }

  Future<void> close() async {
    final pending = _opening;
    if (pending != null) await (await pending).close();
    _opening = null;
  }
}
