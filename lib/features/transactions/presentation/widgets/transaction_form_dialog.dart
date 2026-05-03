import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/account_cubit.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
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
  late TextEditingController _commentController;
  late TransactionType _type;
  late DateTime _date;
  int? _categoryId;
  String? _categoryName;
  int? _accountId;
  String? _accountName;
  int? _toAccountId;
  String? _toAccountName;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: widget.initial?.amount.value.toString() ?? '',
    );
    _commentController = TextEditingController(
      text: widget.initial?.comment ?? '',
    );

    _type = widget.initial?.type ?? TransactionType.expense;
    _date = widget.initial?.date.value ?? DateTime.now();
    _categoryId = widget.initial?.categoryId;
    _categoryName = widget.initial?.categoryName;
    _accountId = widget.initial?.accountId;
    _accountName = widget.initial?.accountName;
    _toAccountId = widget.initial?.toAccountId;
    _toAccountName = widget.initial?.toAccountName;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
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

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (!mounted || pickedTime == null) return;

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

    if (_type != TransactionType.transfer &&
        (_categoryId == null || _categoryName == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_accountId == null || _accountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source account')),
      );
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination account')),
        );
        return;
      }

      if (_toAccountId == _accountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Source and destination accounts must differ'),
          ),
        );
        return;
      }
    }

    try {
      final comment = _commentController.text.trim();
      widget.onSubmit(
        TransactionEntity(
          id: widget.initial?.id ?? 0,
          type: _type,
          amount: Amount(amount),
          date: TransactionDate(_date),
          categoryId: _categoryId ?? 1,
          categoryName: _categoryName ?? 'Перевод',
          accountId: _accountId!,
          accountName: _accountName!,
          toAccountId: _type == TransactionType.transfer
              ? _toAccountId
              : _accountId,
          toAccountName: _type == TransactionType.transfer
              ? _toAccountName
              : _accountName,
          comment: comment.isEmpty ? null : comment,
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
    final categories = context.watch<CategoryCubit>().state.categories;
    final accounts = context.watch<AccountCubit>().state.accounts;
    final filteredCategories = categories
        .where((category) => category.type == _type)
        .toList();
    final isTransfer = _type == TransactionType.transfer;

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

    final AccountEntity? selectedAccount = accounts.isNotEmpty
        ? accounts.firstWhere(
            (account) => account.id == _accountId,
            orElse: () => accounts.first,
          )
        : null;

    final AccountEntity? selectedToAccount = accounts.isNotEmpty
        ? accounts.firstWhere(
            (account) => account.id == _toAccountId,
            orElse: () {
              if (accounts.length > 1) {
                return accounts.firstWhere(
                  (account) => account.id != _accountId,
                  orElse: () => accounts.first,
                );
              }
              return accounts.first;
            },
          )
        : null;

    if ((_accountId == null ||
            !accounts.any((account) => account.id == _accountId)) &&
        selectedAccount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _accountId = selectedAccount.id;
          _accountName = selectedAccount.name;
        });
      });
    }

    if (isTransfer &&
        (_toAccountId == null ||
            !accounts.any((account) => account.id == _toAccountId)) &&
        selectedToAccount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _toAccountId = selectedToAccount.id;
          _toAccountName = selectedToAccount.name;
        });
      });
    }

    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Add transaction' : 'Edit transaction',
      ),
      content: SizedBox(
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
                DropdownMenuItem(
                  value: TransactionType.transfer,
                  child: Text('Transfer'),
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
                    if (value != TransactionType.transfer) {
                      _toAccountId = null;
                      _toAccountName = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            if (_type != TransactionType.transfer)
              if (filteredCategories.isNotEmpty)
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
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No categories available for this type'),
                ),
            const SizedBox(height: 12),
            if (accounts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('From account'),
                  DropdownButton<int>(
                    value: selectedAccount?.id,
                    isExpanded: true,
                    items: accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      final selected = accounts.firstWhere(
                        (account) => account.id == value,
                        orElse: () => accounts.first,
                      );

                      setState(() {
                        _accountId = selected.id;
                        _accountName = selected.name;
                        if (_type == TransactionType.transfer &&
                            _toAccountId == selected.id) {
                          final nextAccount = accounts.firstWhere(
                            (account) => account.id != selected.id,
                            orElse: () => selected,
                          );
                          _toAccountId = nextAccount.id;
                          _toAccountName = nextAccount.name;
                        }
                      });
                    },
                  ),
                  if (_type == TransactionType.transfer) ...[
                    const SizedBox(height: 12),
                    const Text('To account'),
                    DropdownButton<int>(
                      value: selectedToAccount?.id,
                      isExpanded: true,
                      items: accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        final selected = accounts.firstWhere(
                          (account) => account.id == value,
                          orElse: () => accounts.first,
                        );

                        setState(() {
                          _toAccountId = selected.id;
                          _toAccountName = selected.name;
                        });
                      },
                    ),
                  ],
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No accounts available'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              keyboardType: TextInputType.text,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Comment',
                hintText: 'Optional comment',
              ),
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
