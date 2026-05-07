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

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  void _resubscribe(int profileId) {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();

    emit(AccountState.initial());

    _accountsSubscription = watchAccountsUseCase(profileId).listen((accounts) {
      emit(state.copyWith(accounts: accounts));
    });

    _transactionsSubscription = watchTransactionsUseCase(profileId).listen((
      transactions,
    ) {
      final balances = calculateAccountBalancesUseCase(transactions);
      final totalBalance = balances.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      emit(state.copyWith(balances: balances, totalBalance: totalBalance));
    });
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
