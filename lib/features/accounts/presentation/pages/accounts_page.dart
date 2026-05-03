import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../cubit/account_cubit.dart';
import '../cubit/account_state.dart';
import '../widgets/account_form_dialog.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.accounts),
      appBar: AppBar(title: const Text('Accounts')),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          if (state.accounts.isEmpty) {
            return const Center(child: Text('No accounts yet'));
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total balance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      state.totalBalance.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: state.totalBalance < 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: state.accounts.length,
                  itemBuilder: (context, index) {
                    final account = state.accounts[index];
                    final balance = state.balances[account.id] ?? 0;
                    return ListTile(
                      title: Text(account.name),
                      subtitle: Text(
                        account.isFallback ? 'Default account' : 'Custom',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            balance.toStringAsFixed(2),
                            style: TextStyle(
                              color: balance < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AccountFormDialog(
                                  initial: account,
                                  onSubmit: (updated) {
                                    context.read<AccountCubit>().updateAccount(
                                      updated,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              account.isFallback ? Icons.lock : Icons.delete,
                            ),
                            onPressed: account.isFallback
                                ? null
                                : () {
                                    context.read<AccountCubit>().deleteAccount(
                                      account.id,
                                    );
                                  },
                          ),
                        ],
                      ),
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
          showDialog(
            context: context,
            builder: (_) => AccountFormDialog(
              onSubmit: (account) {
                context.read<AccountCubit>().addAccount(account);
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
