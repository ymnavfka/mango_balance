import 'package:flutter/material.dart';

import '../../../../core/services/app_error_notifier.dart';
import 'package:flutter/services.dart';
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
import '../../../transactions/presentation/cubit/transaction_cubit.dart';
import '../../domain/entities/notify_lead.dart';
import '../../domain/entities/recurring_interval.dart';
import '../../domain/entities/recurring_payment.dart';

class RecurringPaymentFormDialog extends StatefulWidget {
  const RecurringPaymentFormDialog({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final RecurringPaymentEntity? initial;
  final void Function(RecurringPaymentEntity payment) onSubmit;

  @override
  State<RecurringPaymentFormDialog> createState() =>
      _RecurringPaymentFormDialogState();
}

class _RecurringPaymentFormDialogState
    extends State<RecurringPaymentFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _intervalCountController;
  late TextEditingController _notifyValueController;
  late TransactionType _type;
  late RecurringInterval _intervalUnit;
  late NotifyLeadUnit _notifyUnit;
  late DateTime _startDate;
  late bool _isActive;
  late bool _notifyEnabled;
  int? _categoryId;
  String? _categoryName;
  int? _accountId;
  String? _accountName;

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _amountController = TextEditingController(
      text: initial == null ? '' : initial.amount.toString(),
    );
    _intervalCountController = TextEditingController(
      text: (initial?.intervalCount ?? 1).toString(),
    );
    _notifyValueController = TextEditingController(
      text: (initial?.notifyValue ?? 1).toString(),
    );
    _notifyEnabled = initial == null ? true : initial.notifyValue != null;
    _notifyUnit = initial?.notifyUnit ?? NotifyLeadUnit.day;
    _type = initial?.type ?? TransactionType.expense;
    _intervalUnit = initial?.intervalUnit ?? RecurringInterval.month;
    final now = DateTime.now();
    _startDate = initial?.startDate ?? DateTime(now.year, now.month, now.day);
    _isActive = initial?.isActive ?? true;
    _categoryId = initial?.categoryId;
    _categoryName = initial?.categoryName;
    _accountId = initial?.accountId;
    _accountName = initial?.accountName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _intervalCountController.dispose();
    _notifyValueController.dispose();
    super.dispose();
  }

  int get _intervalCount {
    final parsed = int.tryParse(_intervalCountController.text.trim()) ?? 1;
    return parsed < 1 ? 1 : parsed;
  }

  int get _notifyValue {
    final parsed = int.tryParse(_notifyValueController.text.trim()) ?? 1;
    return parsed < 1 ? 1 : parsed;
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _showError(String message) {
    showAppNotice(message);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Введите название платежа');
      return;
    }
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      _showError('Сумма должна быть больше нуля');
      return;
    }
    if (_categoryId == null || _categoryName == null) {
      _showError('Выберите категорию');
      return;
    }
    if (_accountId == null || _accountName == null) {
      _showError('Выберите счёт');
      return;
    }

    widget.onSubmit(
      RecurringPaymentEntity(
        id: widget.initial?.id ?? 0,
        name: name,
        type: _type,
        amount: amount,
        categoryId: _categoryId!,
        categoryName: _categoryName!,
        accountId: _accountId!,
        accountName: _accountName!,
        intervalUnit: _intervalUnit,
        intervalCount: _intervalCount,
        startDate: _startDate,
        nextRunDate: _startDate,
        isActive: _isActive,
        notifyValue: _notifyEnabled ? _notifyValue : null,
        notifyUnit: _notifyEnabled ? _notifyUnit : null,
      ),
    );
    Navigator.pop(context);
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

    return AppDialog(
      title: widget.initial == null
          ? 'Новый регулярный платёж'
          : 'Редактирование',
      primaryLabel: widget.initial == null ? 'Добавить' : 'Сохранить',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Название', top: 0),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Например: Зарплата, Подписка',
              prefixIcon: Icon(Icons.event_repeat_rounded),
            ),
          ),
          const FormFieldLabel('Тип операции'),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Пополнение'),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Списание'),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() {
                _type = selection.first;
                // Сбрасываем категорию: build() заново выберет самую популярную
                // категорию нового типа.
                _categoryId = null;
                _categoryName = null;
              });
            },
          ),
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
          const FormFieldLabel('Счёт'),
          if (accounts.isNotEmpty)
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
                });
              },
            )
          else
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
          const FormFieldLabel('Период повторения'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _intervalCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixText: 'кажд. ',
                    hintText: '1',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppDropdownField<RecurringInterval>(
                  value: _intervalUnit,
                  items: RecurringInterval.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.singularLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _intervalUnit = value);
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              recurrenceLabel(_intervalUnit, _intervalCount),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const FormFieldLabel('Дата первого платежа'),
          _DateField(text: _formatDate(_startDate), onTap: _pickStartDate),
          const FormFieldLabel('Оповещение'),
          Row(
            children: [
              Checkbox(
                value: _notifyEnabled,
                visualDensity: VisualDensity.compact,
                onChanged: (value) =>
                    setState(() => _notifyEnabled = value ?? false),
              ),
              const Expanded(child: Text('Напоминать заранее')),
            ],
          ),
          if (_notifyEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _notifyValueController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixText: 'за ',
                      hintText: '1',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdownField<NotifyLeadUnit>(
                    value: _notifyUnit,
                    items: NotifyLeadUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.singularLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _notifyUnit = value);
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                notifyLeadLabel(_notifyUnit, _notifyValue),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
