import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'edit_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.database,
    required this.expenseId,
  });
  final DatabaseHelper database;
  final int expenseId;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Expense?> _expense;
  bool _deleting = false;
  @override
  void initState() {
    super.initState();
    _expense = widget.database.getExpenseById(widget.expenseId);
  }

  void _reload() {
    final next = widget.database.getExpenseById(widget.expenseId);
    setState(() {
      _expense = next;
    });
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) =>
            EditScreen(database: widget.database, expenseId: widget.expenseId),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _delete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khoản chi?'),
        content: Text(
          'Xóa “${expense.name}” (${money(expense.amount)})? Bạn không thể khôi phục khoản chi này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.database.deleteExpense(widget.expenseId);
      if (!mounted) return;
      showMessage(context, 'Đã xóa khoản chi.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Chưa xóa được khoản chi. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: Scaffold(
      appBar: AppBar(title: const Text('Chi tiết khoản chi')),
      body: SafeArea(
        child: ContentWidth(
          child: LoadView<Expense?>(
            future: _expense,
            onRetry: _reload,
            builder: (expense) {
              if (expense == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Khoản chi này không còn tồn tại.'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryIcon(expense.category, size: 64),
                    const SizedBox(height: 20),
                    SelectableText(
                      expense.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      money(expense.amount),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    _info('Danh mục', expense.category),
                    _info('Ngày chi tiêu', displayDate(expense.date)),
                    _info(
                      'Ghi chú',
                      expense.note.isEmpty ? 'Không có ghi chú' : expense.note,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _deleting ? null : _edit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sửa khoản chi'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _deleting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Quay lại'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _deleting ? null : () => _delete(expense),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(_deleting ? 'Đang xóa…' : 'Xóa khoản chi'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted)),
        const SizedBox(height: 6),
        SelectableText(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}
