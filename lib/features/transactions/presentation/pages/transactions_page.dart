import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';
import '../widgets/transaction_form_dialog.dart';

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
                              onTap: () {
                                final cubit = context.read<TransactionCubit>();

                                showDialog(
                                  context: context,
                                  builder: (_) => TransactionFormDialog(
                                    initial: tx,
                                    onSubmit: (updated) =>
                                        cubit.updateTransaction(updated),
                                  ),
                                );
                              },
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
        onPressed: () {
          final cubit = context.read<TransactionCubit>();

          showDialog(
            context: context,
            builder: (_) => TransactionFormDialog(
              onSubmit: (tx) => cubit.addTransaction(tx),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
