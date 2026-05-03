import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/account.dart';
import '../../domain/usecases/add_account.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/update_account.dart';
import '../../domain/usecases/watch_accounts.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/usecases/watch_transactions.dart';
import '../../../../core/enums/transaction_type.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({
    required this.watchAccountsUseCase,
    required this.watchTransactionsUseCase,
    required this.addAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountUseCase,
  }) : super(AccountState.initial()) {
    _init();
  }

  final WatchAccounts watchAccountsUseCase;
  final WatchTransactions watchTransactionsUseCase;
  final AddAccount addAccountUseCase;
  final UpdateAccount updateAccountUseCase;
  final DeleteAccount deleteAccountUseCase;

  late final StreamSubscription<List<AccountEntity>> _accountsSubscription;
  late final StreamSubscription<List<TransactionEntity>>
  _transactionsSubscription;

  void _init() {
    _accountsSubscription = watchAccountsUseCase().listen((accounts) {
      emit(state.copyWith(accounts: accounts));
    });

    _transactionsSubscription = watchTransactionsUseCase().listen((
      transactions,
    ) {
      final balances = _calculateAccountBalances(transactions);
      final totalBalance = balances.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      emit(state.copyWith(balances: balances, totalBalance: totalBalance));
    });
  }

  @override
  Future<void> close() async {
    await _accountsSubscription.cancel();
    await _transactionsSubscription.cancel();
    return super.close();
  }

  Future<void> addAccount(AccountEntity account) async {
    await addAccountUseCase(account);
  }

  Map<int, double> _calculateAccountBalances(
    List<TransactionEntity> transactions,
  ) {
    final balances = <int, double>{};

    for (final tx in transactions) {
      balances[tx.accountId] = (balances[tx.accountId] ?? 0);
      if (tx.type == TransactionType.income) {
        balances[tx.accountId] = balances[tx.accountId]! + tx.amount.value;
      } else if (tx.type == TransactionType.expense) {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount.value;
      } else {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount.value;
        if (tx.toAccountId != null) {
          balances[tx.toAccountId!] =
              (balances[tx.toAccountId!] ?? 0) + tx.amount.value;
        }
      }
    }

    return balances;
  }

  Future<void> updateAccount(AccountEntity account) async {
    await updateAccountUseCase(account);
  }

  Future<void> deleteAccount(int id) async {
    await deleteAccountUseCase(id);
  }
}
