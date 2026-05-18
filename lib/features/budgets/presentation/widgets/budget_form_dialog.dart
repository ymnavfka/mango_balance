import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/popularity_ranker.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../categories/presentation/cubit/category_state.dart';
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
      _showError('Name must not be empty');
      return;
    }
    final limit = double.tryParse(_limitController.text.replaceAll(',', '.'));
    if (limit == null || limit <= 0) {
      _showError('Limit must be a positive number');
      return;
    }
    if (!_allCategories && _selectedCategoryIds.isEmpty) {
      _showError('Select at least one category or enable "All categories"');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add budget' : 'Edit budget'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Limit amount'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Period',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BudgetPeriod.values.map((period) {
                  return ChoiceChip(
                    label: Text(period.label),
                    selected: _period == period,
                    onSelected: (_) => setState(() => _period = period),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All expense categories'),
                subtitle: const Text('Includes categories added in the future'),
                value: _allCategories,
                onChanged: (value) {
                  setState(() {
                    _allCategories = value ?? false;
                    if (_allCategories) {
                      _selectedCategoryIds = {};
                    }
                  });
                },
              ),
              if (!_allCategories)
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    final allTransactions = context
                        .watch<TransactionCubit>()
                        .state
                        .allTransactions;
                    final ranker = PopularityRanker(
                      transactions: allTransactions,
                    );
                    final expenseCategories = ranker.sortCategories(
                      state.categories.where(
                        (c) => c.type == TransactionType.expense,
                      ),
                    );
                    if (expenseCategories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No expense categories available'),
                      );
                    }
                    return Column(
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
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
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
