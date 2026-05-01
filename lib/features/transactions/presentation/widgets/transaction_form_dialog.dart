import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/value_objects/amount.dart';
import '../../domain/value_objects/transaction_date.dart';

class TransactionFormDialog extends StatefulWidget {
  const TransactionFormDialog({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final TransactionEntity? initial;
  final void Function(TransactionEntity tx) onSubmit;

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  late TextEditingController _amountController;
  late TransactionType _type;
  late DateTime _date;
  int? _categoryId;
  String? _categoryName;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: widget.initial?.amount.value.toString() ?? '',
    );

    _type = widget.initial?.type ?? TransactionType.expense;
    _date = widget.initial?.date.value ?? DateTime.now();
    _categoryId = widget.initial?.categoryId;
    _categoryName = widget.initial?.categoryName;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (!mounted) return;
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (!mounted) return;
    if (pickedTime == null) return;

    final newDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _date = newDate;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (_categoryId == null || _categoryName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    try {
      widget.onSubmit(
        TransactionEntity(
          id: widget.initial?.id ?? 0,
          type: _type,
          amount: Amount(amount),
          date: TransactionDate(_date),
          categoryId: _categoryId!,
          categoryName: _categoryName!,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchCategories = getIt<WatchCategories>();

    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Add transaction' : 'Edit transaction',
      ),
      content: StreamBuilder<List<CategoryEntity>>(
        stream: watchCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          final filteredCategories = categories
              .where((category) => category.type == _type)
              .toList();

          final CategoryEntity? selectedCategory = filteredCategories.isNotEmpty
              ? filteredCategories.firstWhere(
                  (category) => category.id == _categoryId,
                  orElse: () => filteredCategories.first,
                )
              : null;

          if ((_categoryId == null ||
                  !filteredCategories.any(
                    (category) => category.id == _categoryId,
                  )) &&
              selectedCategory != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _categoryId = selectedCategory.id;
                _categoryName = selectedCategory.name;
              });
            });
          }

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<TransactionType>(
                  isExpanded: true,
                  value: _type,
                  items: const [
                    DropdownMenuItem(
                      value: TransactionType.income,
                      child: Text('Income'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.expense,
                      child: Text('Expense'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      final newCategories = categories
                          .where((category) => category.type == value)
                          .toList();
                      setState(() {
                        _type = value;
                        if (newCategories.isNotEmpty) {
                          _categoryId = newCategories.first.id;
                          _categoryName = newCategories.first.name;
                        } else {
                          _categoryId = null;
                          _categoryName = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Failed to load categories'),
                  ),
                if (snapshot.hasData)
                  DropdownButton<int>(
                    value: selectedCategory?.id,
                    isExpanded: true,
                    items: filteredCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      final selected = filteredCategories.firstWhere(
                        (category) => category.id == value,
                        orElse: () => filteredCategories.first,
                      );

                      setState(() {
                        _categoryId = selected.id;
                        _categoryName = selected.name;
                      });
                    },
                  ),
                if (filteredCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No categories available for this type'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(_formatDate(_date))),
                    TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Select date'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
