import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.database});
  final DatabaseHelper database;
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<Map<String, int>> _totals;
  @override
  void initState() {
    super.initState();
    _totals = widget.database.getTotalByCategory();
  }

  void _reload() => setState(() {
    _totals = widget.database.getTotalByCategory();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thống kê')),
    body: SafeArea(
      child: ContentWidth(
        child: LoadView<Map<String, int>>(
          future: _totals,
          onRetry: _reload,
          builder: (totals) {
            final total = totals.values.fold<int>(
              0,
              (sum, value) => sum + value,
            );
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TotalPanel(
                  total: total,
                  caption: 'Tất cả khoản chi • 5 danh mục',
                ),
                const SizedBox(height: 28),
                Text(
                  'Tiền của bạn đã đi đâu?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tỷ trọng từng danh mục trong tổng chi tiêu.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                if (total > 0) ...[
                  Semantics(
                    label: 'Tỷ trọng chi tiêu theo danh mục',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final category in expenseCategories)
                              if (totals[category]! > 0)
                                Expanded(
                                  flex: totals[category]!,
                                  child: ColoredBox(
                                    color: categoryStyle(category).$1,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                if (total == 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Chưa có khoản chi nào. Thêm khoản chi để xem thống kê.',
                    ),
                  ),
                for (final category in expenseCategories) ...[
                  _categoryRow(category, totals[category]!, total),
                  const SizedBox(height: 26),
                ],
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _categoryRow(String category, int amount, int total) {
    final ratio = total == 0 ? 0.0 : amount / total;
    final percent = ratio * 100;
    final percentText =
        (percent == percent.roundToDouble()
                ? percent.toStringAsFixed(0)
                : percent.toStringAsFixed(1))
            .replaceAll('.', ',');
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryIcon(category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(money(amount), style: const TextStyle(color: muted)),
                ],
              ),
            ),
            Text(
              '$percentText%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 7,
          borderRadius: BorderRadius.circular(4),
          color: categoryStyle(category).$1,
          backgroundColor: line,
          semanticsLabel: category,
          semanticsValue: '$percentText%',
        ),
      ],
    );
  }
}
