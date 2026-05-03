import '../../domain/entities/account.dart';

class AccountState {
  AccountState({
    required this.accounts,
    required this.balances,
    required this.totalBalance,
  });

  factory AccountState.initial() {
    return AccountState(accounts: [], balances: {}, totalBalance: 0);
  }

  final List<AccountEntity> accounts;
  final Map<int, double> balances;
  final double totalBalance;

  AccountState copyWith({
    List<AccountEntity>? accounts,
    Map<int, double>? balances,
    double? totalBalance,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      balances: balances ?? this.balances,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }
}
