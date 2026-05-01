import '../entities/account.dart';
import '../repositories/account_repository.dart';

class UpdateAccount {
  UpdateAccount(this.repository);

  final AccountRepository repository;

  Future<void> call(AccountEntity account) async {
    await repository.updateAccount(account);
  }
}
