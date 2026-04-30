import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
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

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: widget.initial?.amount.value.toString() ?? '',
    );

    _type = widget.initial?.type ?? TransactionType.expense;
    _date = widget.initial?.date.value ?? DateTime.now();
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

    try {
      widget.onSubmit(
        TransactionEntity(
          id: widget.initial?.id ?? 0,
          type: _type,
          amount: Amount(amount),
          date: TransactionDate(_date),
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
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add' : 'Edit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            onChanged: (value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
          ),

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
      actions: [
        TextButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
