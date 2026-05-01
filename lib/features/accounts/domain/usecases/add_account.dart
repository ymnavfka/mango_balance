import '../entities/account.dart';
import '../repositories/account_repository.dart';

class AddAccount {
  AddAccount(this.repository);

  final AccountRepository repository;

  Future<void> call(AccountEntity account) async {
    await repository.addAccount(account);
  }
}
