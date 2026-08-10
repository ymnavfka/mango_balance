import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/app_error_notifier.dart';
import '../../../../core/utils/popularity_ranker.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/account_cubit.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/calculator_sheet.dart';
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

  Future<void> _openCalculator() async {
    FocusScope.of(context).unfocus();
    final initial = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CalculatorSheet(
        initialValue: initial,
        onChanged: (value) {
          _amountController.text = formatAmountForField(value);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
        0.0;

    if (_type != TransactionType.transfer &&
        (_categoryId == null || _categoryName == null)) {
      showAppNotice('Выберите категорию');
      return;
    }

    if (_accountId == null || _accountName == null) {
      showAppNotice('Выберите счёт-источник');
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountName == null) {
        showAppNotice('Выберите счёт-получатель');
        return;
      }

      if (_toAccountId == _accountId) {
        showAppNotice('Счёт-источник и счёт-получатель должны отличаться');
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
      showAppError(e);
    }
  }

  // Создаёт категорию прямо из формы транзакции и сразу выбирает её. Тип
  // фиксируется по текущему типу операции, чтобы категория гарантированно
  // подходила к этой транзакции.
  Future<void> _createCategory() async {
    final cubit = context.read<CategoryCubit>();
    final type = _type;

    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NewCategoryDialog(type: type),
    );
    if (!mounted || name == null) return;

    try {
      final id = await cubit.addCategory(
        CategoryEntity(id: 0, name: name, type: type, isFallback: false),
      );
      // Ждём, пока поток категорий обновится: иначе build() не найдёт новую
      // категорию в списке и сбросит выбор на «популярную».
      if (!cubit.state.categories.any((category) => category.id == id)) {
        await cubit.stream.firstWhere(
          (state) => state.categories.any((category) => category.id == id),
        );
      }
      if (!mounted) return;
      setState(() {
        _categoryId = id;
        _categoryName = name;
      });
    } catch (e) {
      showAppError(e);
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
              setState(() {
                _type = value;
                // Сбрасываем категорию: build() заново выберет самую
                // популярную категорию нового типа (по PopularityRanker),
                // как и при первичном открытии формы.
                _categoryId = null;
                _categoryName = null;
                if (value != TransactionType.transfer) {
                  _toAccountId = null;
                  _toAccountName = null;
                }
              });
            },
          ),
          if (_type != TransactionType.transfer) ...[
            const FormFieldLabel('Категория'),
            Row(
              children: [
                Expanded(
                  child: filteredCategories.isNotEmpty
                      ? AppDropdownField<int>(
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
                      : const _EmptyFieldBox('Категорий пока нет'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _AddCategoryButton(onTap: _createCategory),
              ],
            ),
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
            decoration: InputDecoration(
              hintText: '0,00',
              prefixIcon: const Icon(Icons.payments_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate_rounded),
                color: AppColors.brand,
                tooltip: 'Калькулятор',
                onPressed: _openCalculator,
              ),
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

/// Нейтральный «заполнитель» в стиле поля — показывается вместо выпадающего
/// списка, когда категорий нужного типа ещё нет.
class _EmptyFieldBox extends StatelessWidget {
  const _EmptyFieldBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textTertiary)),
    );
  }
}

/// Квадратная кнопка «+» рядом со списком категорий для быстрого создания
/// новой категории прямо из формы транзакции.
class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Новая категория',
      child: Material(
        color: AppColors.brandContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add_rounded, color: AppColors.brand),
          ),
        ),
      ),
    );
  }
}

/// Мини-диалог создания категории из формы транзакции: запрашивает только
/// название, тип задаётся снаружи (совпадает с типом операции).
class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog({required this.type});

  final TransactionType type;

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      showAppNotice('Название категории не должно быть пустым');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.type == TransactionType.income
        ? 'Доход'
        : 'Расход';

    return AppDialog(
      title: 'Новая категория',
      subtitle: 'Тип: $typeLabel',
      primaryLabel: 'Добавить',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Название категории', top: 0),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Например: Продукты',
              prefixIcon: Icon(Icons.label_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
