import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
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
        const SnackBar(content: Text('Category name must not be empty')),
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

    return AlertDialog(
      title: Text(widget.initial == null ? 'Add category' : 'Edit category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            enabled: !isFallback,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          const SizedBox(height: 12),
          DropdownButton<TransactionType>(
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
            onChanged: isFallback
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
          ),
          if (isFallback)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                'Fallback categories cannot be edited or deleted',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isFallback ? null : _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
