import 'package:flutter/material.dart';

import '../../../../core/services/app_error_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/popularity_ranker.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../categories/presentation/cubit/category_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../../../transactions/presentation/cubit/transaction_cubit.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_period.dart';

class BudgetFormDialog extends StatefulWidget {
  const BudgetFormDialog({super.key, this.initial, required this.onSubmit});

  final BudgetEntity? initial;
  final void Function(BudgetEntity budget) onSubmit;

  @override
  State<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _limitController;
  late BudgetPeriod _period;
  late bool _allCategories;
  late Set<int> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _limitController = TextEditingController(
      text: widget.initial == null
          ? ''
          : widget.initial!.limitAmount.toStringAsFixed(2),
    );
    _period = widget.initial?.period ?? BudgetPeriod.month;
    _allCategories = widget.initial?.allCategories ?? true;
    _selectedCategoryIds = (widget.initial?.categoryIds ?? const <int>[])
        .toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Название не должно быть пустым');
      return;
    }
    final limit = double.tryParse(_limitController.text.replaceAll(',', '.'));
    if (limit == null || limit <= 0) {
      _showError('Лимит должен быть положительным числом');
      return;
    }
    if (!_allCategories && _selectedCategoryIds.isEmpty) {
      _showError(
        'Выберите хотя бы одну категорию или включите «Все категории»',
      );
      return;
    }

    final List<int> ids;
    if (_allCategories) {
      ids = const [];
    } else {
      ids = _selectedCategoryIds.toList()..sort();
    }

    final budget = BudgetEntity(
      id: widget.initial?.id ?? 0,
      name: name,
      limitAmount: limit,
      period: _period,
      allCategories: _allCategories,
      categoryIds: ids,
    );

    widget.onSubmit(budget);
    Navigator.pop(context);
  }

  void _showError(String message) {
    showAppNotice(message);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.initial == null ? 'Новый бюджет' : 'Редактирование',
      primaryLabel: widget.initial == null ? 'Добавить' : 'Сохранить',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Название', top: 0),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Например: Продукты на месяц',
              prefixIcon: Icon(Icons.savings_rounded),
            ),
          ),
          const FormFieldLabel('Лимит'),
          TextField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0,00',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
          ),
          const FormFieldLabel('Период'),
          SegmentedButton<BudgetPeriod>(
            segments: BudgetPeriod.values
                .map(
                  (period) =>
                      ButtonSegment(value: period, label: Text(period.label)),
                )
                .toList(),
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _period = selection.first),
          ),
          const FormFieldLabel('Категории'),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Все категории расходов',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Включая добавленные в будущем',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _allCategories,
                  onChanged: (value) {
                    setState(() {
                      _allCategories = value;
                      if (_allCategories) {
                        _selectedCategoryIds = {};
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (!_allCategories)
            BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                final allTransactions = context
                    .watch<TransactionCubit>()
                    .state
                    .allTransactions;
                final ranker = PopularityRanker(transactions: allTransactions);
                final expenseCategories = ranker.sortCategories(
                  state.categories.where(
                    (c) => c.type == TransactionType.expense,
                  ),
                );
                if (expenseCategories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Нет доступных категорий расходов',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expenseCategories.map((category) {
                      return _CategoryCheckbox(
                        category: category,
                        checked: _selectedCategoryIds.contains(category.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryCheckbox extends StatelessWidget {
  const _CategoryCheckbox({
    required this.category,
    required this.checked,
    required this.onChanged,
  });

  final CategoryEntity category;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(category.name),
      value: checked,
      onChanged: onChanged,
    );
  }
}
