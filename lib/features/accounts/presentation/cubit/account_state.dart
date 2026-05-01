import '../../domain/entities/account.dart';

class AccountState {
  AccountState({required this.accounts});

  factory AccountState.initial() {
    return AccountState(accounts: []);
  }

  final List<AccountEntity> accounts;

  AccountState copyWith({List<AccountEntity>? accounts}) {
    return AccountState(accounts: accounts ?? this.accounts);
  }
}
