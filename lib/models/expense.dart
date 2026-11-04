const expenseCategories = ['Ăn uống', 'Đi lại', 'Học tập', 'Giải trí', 'Khác'];

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String databaseDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class Expense {
  const Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });
  final int? id;
  final String name;
  final int amount;
  final String category;
  final DateTime date;
  final String note;

  factory Expense.fromMap(Map<String, Object?> row) => Expense(
    id: row['id'] as int,
    name: row['name'] as String,
    amount: row['amount'] as int,
    category: row['category'] as String,
    date: DateTime.parse(row['date'] as String),
    note: row['note'] as String? ?? '',
  );

  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'amount': amount,
    'category': category,
    'date': databaseDate(date),
    'note': note.trim(),
  };

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Tên khoản chi không được trống.');
    }
    if (amount <= 0 || amount > 999999999999999) {
      throw ArgumentError('Số tiền phải từ 1 đến 999.999.999.999.999 đồng.');
    }
    if (!expenseCategories.contains(category)) {
      throw ArgumentError('Danh mục không hợp lệ.');
    }
    if (dateOnly(date).isAfter(dateOnly(DateTime.now()))) {
      throw ArgumentError('Ngày chi tiêu không được sau hôm nay.');
    }
  }
}

class ExpenseSummary {
  const ExpenseSummary(this.expenses, this.total);
  final List<Expense> expenses;
  final int total;
}
