import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/popularity_ranker.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../transactions/presentation/cubit/transaction_cubit.dart';
import '../../domain/entities/account.dart';
import '../cubit/account_cubit.dart';
import '../cubit/account_state.dart';
import '../widgets/account_form_dialog.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.accounts),
      appBar: AppBar(title: const Text('Счета')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<AccountCubit, AccountState>(
          builder: (context, state) {
            if (state.accounts.isEmpty) {
              return const EmptyState(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Счетов ещё нет',
                message: 'Добавьте счёт или кошелёк, чтобы вести по нему учёт.',
              );
            }

            // Сортируем счета по популярности так же, как на экране транзакций.
            final allTransactions = context
                .watch<TransactionCubit>()
                .state
                .allTransactions;
            final sortedAccounts = PopularityRanker(
              transactions: allTransactions,
            ).sortAccounts(state.accounts);

            return ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              children: [
                _TotalCard(total: state.totalBalance),
                const SizedBox(height: 6),
                ...sortedAccounts.map((account) {
                  final balance = state.balances[account.id] ?? 0;
                  return _AccountTile(account: account, balance: balance);
                }),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Счёт'),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.brandContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Общий баланс',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.amount(total),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.balance});

  final AccountEntity account;
  final double balance;

  void _edit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AccountFormDialog(
        initial: account,
        onSubmit: (updated) {
          context.read<AccountCubit>().updateAccount(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _edit(context),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outline),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    account.isFallback
                        ? Icons.account_balance_wallet_rounded
                        : Icons.credit_card_rounded,
                    color: AppColors.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.isFallback
                            ? 'Счёт по умолчанию'
                            : 'Пользовательский',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatMoney(balance),
                      style: TextStyle(
                        color: AppColors.amount(balance),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _edit(context);
                    } else if (value == 'delete') {
                      context.read<AccountCubit>().deleteAccount(account.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Редактировать'),
                        ],
                      ),
                    ),
                    if (!account.isFallback)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.expense,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Удалить',
                              style: TextStyle(color: AppColors.expense),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
