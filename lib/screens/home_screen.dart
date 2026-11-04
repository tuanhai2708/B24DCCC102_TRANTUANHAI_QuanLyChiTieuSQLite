import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.database});
  final DatabaseHelper database;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _search = TextEditingController();
  String? _category;
  late Future<ExpenseSummary> _summary;
  bool get _filtered => _search.text.trim().isNotEmpty || _category != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _summary = _query();
  }

  Future<ExpenseSummary> _query() =>
      widget.database.getSummary(keyword: _search.text, category: _category);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _summary = _query();
    });
    // FutureBuilder hiển thị lỗi, RefreshIndicator vẫn dừng đúng cách.
    try {
      await _summary;
    } catch (_) {
      /* handled by LoadView */
    }
  }

  Future<void> _open(Widget screen) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sổ chi tiêu'),
      actions: [
        IconButton(
          tooltip: 'Thống kê',
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: () => _open(StatisticsScreen(database: widget.database)),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => LoginScreen(database: widget.database),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => _refresh(),
                decoration: InputDecoration(
                  hintText: 'Tìm tên khoản chi',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _search.clear();
                            _refresh();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category ?? 'Tất cả danh mục',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.filter_list_rounded),
                ),
                items: ['Tất cả danh mục', ...expenseCategories]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  _category = value == 'Tất cả danh mục' ? null : value;
                  _refresh();
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LoadView<ExpenseSummary>(
                  future: _summary,
                  onRetry: _refresh,
                  builder: (summary) => RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        TotalPanel(
                          total: summary.total,
                          label: _filtered
                              ? 'Tổng chi theo bộ lọc'
                              : 'Tổng chi tiêu',
                          caption:
                              '${summary.expenses.length} khoản chi${_filtered ? ' phù hợp' : ' đã ghi lại'}',
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Các khoản chi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (summary.expenses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 46,
                                  color: muted,
                                ),
                                const SizedBox(height: 16),
                                const Text('Chưa có khoản chi nào'),
                                const SizedBox(height: 8),
                                Text(
                                  _filtered
                                      ? 'Thử đổi từ khóa hoặc danh mục.'
                                      : 'Nhấn Thêm khoản chi để bắt đầu.',
                                  style: const TextStyle(color: muted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        for (final expense in summary.expenses) ...[
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _open(
                                DetailScreen(
                                  database: widget.database,
                                  expenseId: expense.id!,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CategoryIcon(expense.category),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${expense.category} • ${displayDate(expense.date)}',
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            money(expense.amount),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            onPressed: () => _open(EditScreen(database: widget.database)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm khoản chi'),
          ),
        ),
      ),
    ),
  );
}
