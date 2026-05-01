import '../entities/account.dart';

abstract class AccountRepository {
  Stream<List<AccountEntity>> watchAccounts();
  Future<void> addAccount(AccountEntity account);
  Future<void> updateAccount(AccountEntity account);
  Future<void> deleteAccount(int id);
}
