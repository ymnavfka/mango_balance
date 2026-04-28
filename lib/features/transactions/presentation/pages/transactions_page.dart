import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final cubit = context.read<TransactionCubit>();
          final balance = cubit.calculateBalance(state.transactions);

          return Column(
            children: [
              const SizedBox(height: 16),

              Text(
                balance.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: state.sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = state.sections[sectionIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 заголовок секции
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            section.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 🔹 транзакции
                        ...section.transactions.map((tx) {
                          return Dismissible(
                            key: ValueKey(tx.id),
                            direction: DismissDirection.endToStart,

                            onDismissed: (_) {
                              final cubit = context.read<TransactionCubit>();

                              final removedTransaction = tx;

                              cubit.deleteTransaction(tx.id);

                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Text('Transaction deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        cubit.restoreTransaction(
                                          removedTransaction,
                                          0,
                                        );
                                      },
                                    ),
                                  ),
                                );
                            },

                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),

                            child: ListTile(
                              leading: Icon(
                                tx.type == TransactionType.income
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx.type == TransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                '${tx.type == TransactionType.income ? '+' : '-'}'
                                '${tx.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: tx.type == TransactionType.income
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(_formatDate(tx.date)),
                              onTap: () =>
                                  _showAddDialog(context, transaction: tx),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddDialog(BuildContext context, {TransactionEntity? transaction}) {
    final cubit = context.read<TransactionCubit>();

    final amountController = TextEditingController(
      text: transaction?.amount.toString() ?? '',
    );

    TransactionType selectedType = transaction?.type ?? TransactionType.expense;

    DateTime selectedDate = transaction?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(transaction == null ? 'Add' : 'Edit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<TransactionType>(
                value: selectedType,
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
                    selectedType = value;
                  }
                },
              ),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),

              const SizedBox(height: 12),

              // выбор даты
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_formatDate(selectedDate))),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();

                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: now,
                      );

                      if (pickedDate == null) return;

                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );

                      if (pickedTime == null) return;

                      final newDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      if (newDate.isAfter(now)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Date cannot be in the future'),
                          ),
                        );
                        return;
                      }

                      selectedDate = newDate;
                    },
                    child: const Text('Select date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null) return;

                if (transaction == null) {
                  cubit.addTransaction(
                    TransactionEntity(
                      id: 0, // временно, cubit заменит
                      type: selectedType,
                      amount: amount,
                      date: selectedDate,
                    ),
                  );
                } else {
                  cubit.updateTransaction(
                    transaction.copyWith(
                      type: selectedType,
                      amount: amount,
                      date: selectedDate,
                    ),
                  );
                }

                Navigator.pop(context);
              },
              child: Text(transaction == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}
