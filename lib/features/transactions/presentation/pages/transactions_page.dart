import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../accounts/presentation/cubit/account_cubit.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';
import '../widgets/transaction_form_dialog.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _formatMoney(double value) {
    final sign = value < 0 ? '-' : '';
    return '$sign${value.abs().toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.transactions),
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/categories');
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final accountState = context.watch<AccountCubit>().state;
          final accounts = accountState.accounts;
          final selectedAccount = state.selectedAccountId == null
              ? null
              : accounts
                    .where((account) => account.id == state.selectedAccountId)
                    .isNotEmpty
              ? accounts.firstWhere(
                  (account) => account.id == state.selectedAccountId,
                )
              : null;

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: state.selectedAccountId,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Row(
                        children: [
                          const Expanded(child: Text('Total')),
                          Text(
                            _formatMoney(state.totalBalance),
                            style: TextStyle(
                              color: state.totalBalance < 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...accounts.map((account) {
                      final balance = state.accountBalances[account.id] ?? 0;
                      return DropdownMenuItem<int?>(
                        value: account.id,
                        child: Row(
                          children: [
                            Expanded(child: Text(account.name)),
                            Text(
                              _formatMoney(balance),
                              style: TextStyle(
                                color: balance < 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    context.read<TransactionCubit>().selectAccount(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.selectedAccountId == null
                            ? 'Total balance'
                            : selectedAccount?.name ?? 'Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatMoney(state.selectedBalance),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: state.selectedBalance < 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: state.sections.isEmpty
                    ? const Center(child: Text('No transactions'))
                    : ListView.builder(
                        itemCount: state.sections.length,
                        itemBuilder: (context, sectionIndex) {
                          final section = state.sections[sectionIndex];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              ...section.transactions.map((tx) {
                                return Dismissible(
                                  key: ValueKey(tx.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) {
                                    final cubit = context
                                        .read<TransactionCubit>();
                                    final removedTransaction = tx;
                                    cubit.deleteTransaction(tx.id);
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Transaction deleted',
                                          ),
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
                                      tx.type == TransactionType.transfer
                                          ? Icons.swap_horiz
                                          : tx.type == TransactionType.income
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: tx.type == TransactionType.transfer
                                          ? Colors.blue
                                          : tx.type == TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    title: Text(
                                      '${tx.type == TransactionType.income
                                          ? '+'
                                          : tx.type == TransactionType.expense
                                          ? '-'
                                          : ''}'
                                      '${tx.amount.value.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color:
                                            tx.type == TransactionType.transfer
                                            ? Colors.blue
                                            : tx.type == TransactionType.income
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${tx.type == TransactionType.transfer ? 'Перевод: ${tx.accountName} → ${tx.toAccountName}' : '${tx.categoryName} · ${tx.accountName}'}'
                                      '${tx.comment != null && tx.comment!.isNotEmpty ? '\n${tx.comment}' : ''}',
                                    ),
                                    onTap: () {
                                      final cubit = context
                                          .read<TransactionCubit>();
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
