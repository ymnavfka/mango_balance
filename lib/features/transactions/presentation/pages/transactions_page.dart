import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/popularity_ranker.dart';
import '../../../accounts/presentation/cubit/account_cubit.dart';
import '../../../export/presentation/cubit/export_cubit.dart';
import '../../../export/presentation/widgets/export_dialog.dart';
import '../../../import/presentation/cubit/import_cubit.dart';
import '../../../import/presentation/widgets/import_dialog.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
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
        title: const Text('Транзакции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Экспорт в XLSX',
            onPressed: () {
              final profileCubit = context.read<ProfileCubit>();
              showDialog(
                context: context,
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider<ProfileCubit>.value(value: profileCubit),
                    BlocProvider<ExportCubit>(
                      create: (_) => getIt<ExportCubit>(),
                    ),
                  ],
                  child: const ExportDialog(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Импорт из XLSX',
            onPressed: () {
              final profileCubit = context.read<ProfileCubit>();
              showDialog(
                context: context,
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider<ProfileCubit>.value(value: profileCubit),
                    BlocProvider<ImportCubit>(
                      create: (_) => getIt<ImportCubit>(),
                    ),
                  ],
                  child: const ImportDialog(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final accountState = context.watch<AccountCubit>().state;
          final ranker = PopularityRanker(transactions: state.allTransactions);
          final accounts = ranker.sortAccounts(accountState.accounts);
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
                          const Expanded(child: Text('Итого')),
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
                            ? 'Общий баланс'
                            : selectedAccount?.name ?? 'Счёт',
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _TypeFilterCheckbox(
                      label: 'Доход',
                      type: TransactionType.income,
                      visibleTypes: state.visibleTypes,
                    ),
                    const SizedBox(width: 8),
                    _TypeFilterCheckbox(
                      label: 'Расход',
                      type: TransactionType.expense,
                      visibleTypes: state.visibleTypes,
                    ),
                    const SizedBox(width: 8),
                    _TypeFilterCheckbox(
                      label: 'Перевод',
                      type: TransactionType.transfer,
                      visibleTypes: state.visibleTypes,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DateRangeFilter(range: state.dateRange),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.sections.isEmpty
                    ? const Center(child: Text('Нет транзакций'))
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
                                            'Транзакция удалена',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Отменить',
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

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

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
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _label(),
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isActive)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Сбросить фильтр дат',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      context.read<TransactionCubit>().setDateRange(null),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeFilterCheckbox extends StatelessWidget {
  const _TypeFilterCheckbox({
    required this.label,
    required this.type,
    required this.visibleTypes,
  });

  final String label;
  final TransactionType type;
  final Set<TransactionType> visibleTypes;

  @override
  Widget build(BuildContext context) {
    final isChecked = visibleTypes.contains(type);
    final isOnlyOneActive = visibleTypes.length == 1 && isChecked;
    return Expanded(
      child: InkWell(
        onTap: isOnlyOneActive
            ? null
            : () =>
                  context.read<TransactionCubit>().toggleTransactionType(type),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isChecked,
              onChanged: isOnlyOneActive
                  ? null
                  : (_) => context
                        .read<TransactionCubit>()
                        .toggleTransactionType(type),
            ),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
