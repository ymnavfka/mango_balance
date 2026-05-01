import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/account.dart';
import '../../domain/usecases/add_account.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/update_account.dart';
import '../../domain/usecases/watch_accounts.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({
    required this.watchAccountsUseCase,
    required this.addAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountUseCase,
  }) : super(AccountState.initial()) {
    _init();
  }

  final WatchAccounts watchAccountsUseCase;
  final AddAccount addAccountUseCase;
  final UpdateAccount updateAccountUseCase;
  final DeleteAccount deleteAccountUseCase;

  late final StreamSubscription<List<AccountEntity>> _accountsSubscription;

  void _init() {
    _accountsSubscription = watchAccountsUseCase().listen((accounts) {
      emit(state.copyWith(accounts: accounts));
    });
  }

  @override
  Future<void> close() async {
    await _accountsSubscription.cancel();
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
