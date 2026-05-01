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

          return ListView.builder(
            itemCount: state.accounts.length,
            itemBuilder: (context, index) {
              final account = state.accounts[index];
              return ListTile(
                title: Text(account.name),
                subtitle: Text(
                  account.isFallback ? 'Default account' : 'Custom',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
