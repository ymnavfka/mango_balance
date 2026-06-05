import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/popularity_ranker.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/account_cubit.dart';
import '../../../export/presentation/cubit/export_cubit.dart';
import '../../../export/presentation/widgets/export_dialog.dart';
import '../../../import/presentation/cubit/import_cubit.dart';
import '../../../import/presentation/widgets/import_dialog.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';
import '../widgets/transaction_form_dialog.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  void _openExport(BuildContext context) {
    final profileCubit = context.read<ProfileCubit>();
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<ExportCubit>(create: (_) => getIt<ExportCubit>()),
        ],
        child: const ExportDialog(),
      ),
    );
  }

  void _openImport(BuildContext context) {
    final profileCubit = context.read<ProfileCubit>();
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<ImportCubit>(create: (_) => getIt<ImportCubit>()),
        ],
        child: const ImportDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.transactions),
      appBar: AppBar(
        title: const Text('Транзакции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Экспорт в XLSX',
            onPressed: () => _openExport(context),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Импорт из XLSX',
            onPressed: () => _openImport(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final accountState = context.watch<AccountCubit>().state;
          final ranker = PopularityRanker(transactions: state.allTransactions);
          final accounts = ranker.sortAccounts(accountState.accounts);
          AccountEntity? selectedAccount;
          for (final account in accounts) {
            if (account.id == state.selectedAccountId) {
              selectedAccount = account;
              break;
            }
          }

          return Column(
            children: [
              _BalanceCard(
                label: selectedAccount?.name ?? 'Все счета',
                balance: state.selectedBalance,
              ),
              _AccountChips(
                accounts: accounts,
                selectedId: state.selectedAccountId,
              ),
              const SizedBox(height: AppSpacing.sm),
              _TypeFilters(visibleTypes: state.visibleTypes),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _DateRangeFilter(range: state.dateRange),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: state.sections.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'Пока нет операций',
                        message:
                            'Нажмите «+», чтобы добавить первый доход, '
                            'расход или перевод.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96, top: 4),
                        itemCount: state.sections.length,
                        itemBuilder: (context, sectionIndex) {
                          final section = state.sections[sectionIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  section.title,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.2,
                                      ),
                                ),
                              ),
                              ...section.transactions.map(
                                (tx) => _TransactionTile(transaction: tx),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final cubit = context.read<TransactionCubit>();
          showDialog(
            context: context,
            builder: (_) => TransactionFormDialog(
              onSubmit: (tx) => cubit.addTransaction(tx),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Операция'),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.label, required this.balance});

  final String label;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, Color(0xFF7C6CF5)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountChips extends StatelessWidget {
  const _AccountChips({required this.accounts, required this.selectedId});

  final List<AccountEntity> accounts;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox(height: AppSpacing.sm);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _Chip(
            label: 'Все счета',
            selected: selectedId == null,
            onTap: () => context.read<TransactionCubit>().selectAccount(null),
          ),
          for (final account in accounts)
            _Chip(
              label: account.name,
              selected: selectedId == account.id,
              onTap: () =>
                  context.read<TransactionCubit>().selectAccount(account.id),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.brand : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.outline,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({required this.visibleTypes});

  final Set<TransactionType> visibleTypes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _TypeChip(
            label: 'Доход',
            type: TransactionType.income,
            color: AppColors.income,
            visibleTypes: visibleTypes,
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Расход',
            type: TransactionType.expense,
            color: AppColors.expense,
            visibleTypes: visibleTypes,
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Перевод',
            type: TransactionType.transfer,
            color: AppColors.transfer,
            visibleTypes: visibleTypes,
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.type,
    required this.color,
    required this.visibleTypes,
  });

  final String label;
  final TransactionType type;
  final Color color;
  final Set<TransactionType> visibleTypes;

  @override
  Widget build(BuildContext context) {
    final isChecked = visibleTypes.contains(type);
    final isOnlyOneActive = visibleTypes.length == 1 && isChecked;

    return Expanded(
      child: Material(
        color: isChecked ? color : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: isOnlyOneActive
              ? null
              : () => context.read<TransactionCubit>().toggleTransactionType(
                  type,
                ),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: isChecked ? color : AppColors.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isChecked
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 16,
                  color: isChecked ? Colors.white : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isChecked ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionEntity transaction;

  ({Color color, Color surface, IconData icon}) get _style {
    switch (transaction.type) {
      case TransactionType.income:
        return (
          color: AppColors.income,
          surface: AppColors.incomeSurface,
          icon: Icons.south_west_rounded,
        );
      case TransactionType.expense:
        return (
          color: AppColors.expense,
          surface: AppColors.expenseSurface,
          icon: Icons.north_east_rounded,
        );
      case TransactionType.transfer:
        return (
          color: AppColors.transfer,
          surface: AppColors.transferSurface,
          icon: Icons.swap_horiz_rounded,
        );
    }
  }

  String get _title => transaction.type == TransactionType.transfer
      ? 'Перевод'
      : transaction.categoryName;

  String get _subtitle {
    if (transaction.type == TransactionType.transfer) {
      return '${transaction.accountName} → ${transaction.toAccountName}';
    }
    return transaction.accountName;
  }

  String get _amountText {
    final value = formatMoneyAbs(transaction.amount.value);
    switch (transaction.type) {
      case TransactionType.income:
        return '+$value';
      case TransactionType.expense:
        return '−$value';
      case TransactionType.transfer:
        return value;
    }
  }

  String get _time {
    final d = transaction.date.value;
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final comment = transaction.comment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: ValueKey(transaction.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          final cubit = context.read<TransactionCubit>();
          cubit.deleteTransaction(transaction.id);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: const Text('Транзакция удалена'),
                action: SnackBarAction(
                  label: 'Отменить',
                  onPressed: () => cubit.restoreTransaction(transaction, 0),
                ),
              ),
            );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.expense,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () {
              final cubit = context.read<TransactionCubit>();
              showDialog(
                context: context,
                builder: (_) => TransactionFormDialog(
                  initial: transaction,
                  onSubmit: (updated) => cubit.updateTransaction(updated),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outline),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: style.surface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(style.icon, color: style.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
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
                          _subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (comment != null && comment.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            comment,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _amountText,
                        style: TextStyle(
                          color: style.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _time,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({required this.range});

  final DateTimeRange? range;

  static const _months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  String _label() {
    final r = range;
    if (r == null) return 'За всё время';
    return '${_formatDate(r.start)} – ${_formatDate(r.end)}';
  }

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<TransactionCubit>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: range,
    );
    if (picked != null) {
      await cubit.setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = range != null;

    return Material(
      color: isActive ? AppColors.brandContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isActive ? AppColors.brand : AppColors.outline,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 18,
                color: isActive ? AppColors.brand : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _label(),
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.brandDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (isActive)
                GestureDetector(
                  onTap: () =>
                      context.read<TransactionCubit>().setDateRange(null),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.brand,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
