import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/add_account.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/update_account.dart';
import '../../domain/usecases/watch_accounts.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/usecases/calculate_account_balances.dart';
import '../../../transactions/domain/usecases/watch_transactions.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({
    required this.activeProfile,
    required this.watchAccountsUseCase,
    required this.watchTransactionsUseCase,
    required this.calculateAccountBalancesUseCase,
    required this.addAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountUseCase,
  }) : super(AccountState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final WatchAccounts watchAccountsUseCase;
  final WatchTransactions watchTransactionsUseCase;
  final CalculateAccountBalances calculateAccountBalancesUseCase;
  final AddAccount addAccountUseCase;
  final UpdateAccount updateAccountUseCase;
  final DeleteAccount deleteAccountUseCase;

  StreamSubscription<List<AccountEntity>>? _accountsSubscription;
  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  late final StreamSubscription<int> _profileSubscription;

  List<AccountEntity> _accounts = [];
  List<TransactionEntity> _transactions = [];

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  void _resubscribe(int profileId) {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();

    _accounts = [];
    _transactions = [];
    emit(AccountState.initial());

    _accountsSubscription = watchAccountsUseCase(profileId).listen((accounts) {
      _accounts = accounts;
      _emitState();
    });

    _transactionsSubscription = watchTransactionsUseCase(profileId).listen((
      transactions,
    ) {
      _transactions = transactions;
      _emitState();
    });
  }

  void _emitState() {
    final initialBalances = {
      for (final account in _accounts) account.id: account.initialBalance,
    };
    final balances = calculateAccountBalancesUseCase(
      _transactions,
      initialBalances: initialBalances,
    );
    final totalBalance = balances.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    emit(
      state.copyWith(
        accounts: _accounts,
        balances: balances,
        totalBalance: totalBalance,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _accountsSubscription?.cancel();
    await _transactionsSubscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
  }

  Future<void> addAccount(AccountEntity account) async {
    await addAccountUseCase(account);
  }

  Future<void> updateAccount(AccountEntity account) async {
    await updateAccountUseCase(account);
  }

  Future<void> deleteAccount(int id) async {
    await deleteAccountUseCase(id);
  }
}
