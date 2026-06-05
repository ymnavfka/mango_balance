import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/popularity_ranker.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/account_cubit.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/value_objects/amount.dart';
import '../../domain/value_objects/transaction_date.dart';
import '../cubit/transaction_cubit.dart';

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
      ).showSnackBar(const SnackBar(content: Text('Выберите категорию')));
      return;
    }

    if (_accountId == null || _accountName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите счёт-источник')));
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите счёт-получатель')),
        );
        return;
      }

      if (_toAccountId == _accountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Счёт-источник и счёт-получатель должны отличаться'),
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
    final rawAccounts = context.watch<AccountCubit>().state.accounts;
    final allTransactions = context
        .watch<TransactionCubit>()
        .state
        .allTransactions;
    final ranker = PopularityRanker(transactions: allTransactions);
    final accounts = ranker.sortAccounts(rawAccounts);
    final filteredCategories = ranker.sortCategories(
      categories.where((category) => category.type == _type),
    );
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

    return AppDialog(
      title: widget.initial == null ? 'Новая транзакция' : 'Редактирование',
      primaryLabel: widget.initial == null ? 'Добавить' : 'Сохранить',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Тип операции', top: 0),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Доход'),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Расход'),
              ),
              ButtonSegment(
                value: TransactionType.transfer,
                label: Text('Перевод'),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              final value = selection.first;
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
            },
          ),
          if (_type != TransactionType.transfer) ...[
            const FormFieldLabel('Категория'),
            if (filteredCategories.isNotEmpty)
              AppDropdownField<int>(
                value: selectedCategory?.id,
                items: filteredCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
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
              const _InfoBox('Нет категорий для этого типа'),
          ],
          if (accounts.isNotEmpty) ...[
            FormFieldLabel(isTransfer ? 'Счёт-источник' : 'Счёт'),
            AppDropdownField<int>(
              value: selectedAccount?.id,
              items: accounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  )
                  .toList(),
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
            if (isTransfer) ...[
              const FormFieldLabel('Счёт-получатель'),
              AppDropdownField<int>(
                value: selectedToAccount?.id,
                items: accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
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
          ] else
            const _InfoBox('Нет доступных счетов'),
          const FormFieldLabel('Сумма'),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0,00',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
          ),
          const FormFieldLabel('Комментарий'),
          TextField(
            controller: _commentController,
            keyboardType: TextInputType.text,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Необязательный комментарий',
            ),
          ),
          const FormFieldLabel('Дата и время'),
          _DateField(text: _formatDate(_date), onTap: _pickDateTime),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(
                Icons.event_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const Icon(
                Icons.edit_calendar_rounded,
                size: 18,
                color: AppColors.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
