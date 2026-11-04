import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database_helper.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../widgets/common.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key, required this.database, this.expenseId});
  final DatabaseHelper database;
  final int? expenseId;
  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = expenseCategories.first;
  DateTime _date = dateOnly(DateTime.now());
  bool _loading = true;
  bool _saving = false;
  bool _missing = false;
  String? _loadError;
  String? _saveError;
  bool get _editing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (_editing) {
        final expense = await widget.database.getExpenseById(widget.expenseId!);
        if (!mounted) return;
        if (expense == null) {
          _missing = true;
        } else {
          _name.text = expense.name;
          _amount.text = expense.amount.toString();
          _category = expense.category;
          _date = expense.date;
          _note.text = expense.note;
        }
      }
    } catch (_) {
      if (mounted) _loadError = 'Không thể đọc khoản chi. Hãy thử lại.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Chọn ngày chi tiêu',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final expense = Expense(
        id: widget.expenseId,
        name: _name.text,
        amount: int.parse(_amount.text),
        category: _category,
        date: _date,
        note: _note.text,
      );
      if (_editing) {
        final count = await widget.database.updateExpense(expense);
        if (count == 0) throw StateError('missing');
      } else {
        await widget.database.insertExpense(expense);
      }
      if (!mounted) return;
      showMessage(
        context,
        _editing ? 'Đã cập nhật khoản chi.' : 'Đã lưu khoản chi.',
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'Chưa lưu được khoản chi. Kiểm tra dữ liệu rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Sửa khoản chi' : 'Thêm khoản chi'),
      ),
      body: SafeArea(
        child: ContentWidth(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(
                  child: ErrorNotice(message: _loadError!, onRetry: _load),
                )
              : _missing
              ? const Center(child: Text('Khoản chi này không còn tồn tại.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tên và số tiền là thông tin bắt buộc.',
                          style: TextStyle(color: muted),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _name,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'Tên khoản chi',
                            hintText: 'Ví dụ: Bữa trưa ở trường',
                            counterText: '',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập tên khoản chi.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _amount,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Số tiền',
                            suffixText: 'VNĐ',
                            hintText: 'Ví dụ: 35000',
                          ),
                          validator: (v) {
                            final amount = int.tryParse(v ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Nhập số tiền nguyên lớn hơn 0.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                          ),
                          items: expenseCategories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _category = v!),
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          button: true,
                          label: 'Ngày chi tiêu ${displayDate(_date)}',
                          child: InkWell(
                            onTap: _saving ? null : _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Ngày chi tiêu',
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(displayDate(_date)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chọn hôm nay hoặc một ngày trước đó.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _note,
                          enabled: !_saving,
                          minLines: 3,
                          maxLines: 6,
                          maxLength: 2000,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú (không bắt buộc)',
                            alignLabelWithHint: true,
                            counterText: '',
                          ),
                        ),
                        if (_saveError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _saveError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              _saving
                                  ? 'Đang lưu…'
                                  : _editing
                                  ? 'Cập nhật khoản chi'
                                  : 'Lưu khoản chi',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}
