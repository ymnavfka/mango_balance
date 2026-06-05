import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../../domain/entities/category.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key, this.initial, required this.onSubmit});

  final CategoryEntity? initial;
  final void Function(CategoryEntity category) onSubmit;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late TextEditingController _nameController;
  late TransactionType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _type = widget.initial?.type ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Название категории не должно быть пустым'),
        ),
      );
      return;
    }

    final category = CategoryEntity(
      id: widget.initial?.id ?? 0,
      name: name,
      type: _type,
      isFallback: widget.initial?.isFallback ?? false,
    );

    widget.onSubmit(category);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isFallback = widget.initial?.isFallback ?? false;

    return AppDialog(
      title: widget.initial == null ? 'Новая категория' : 'Редактирование',
      primaryLabel: widget.initial == null ? 'Добавить' : 'Сохранить',
      onPrimary: isFallback ? null : _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Название категории', top: 0),
          TextField(
            controller: _nameController,
            enabled: !isFallback,
            autofocus: !isFallback,
            decoration: const InputDecoration(
              hintText: 'Например: Продукты',
              prefixIcon: Icon(Icons.label_rounded),
            ),
          ),
          const FormFieldLabel('Тип'),
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
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: isFallback
                ? null
                : (selection) => setState(() => _type = selection.first),
          ),
          if (isFallback)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Базовые категории нельзя редактировать или удалить',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
