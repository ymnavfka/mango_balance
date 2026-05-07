import '../entities/account.dart';

abstract class AccountRepository {
  Stream<List<AccountEntity>> watchAccounts(int profileId);
  Future<void> addAccount(AccountEntity account);
  Future<void> updateAccount(AccountEntity account);
  Future<void> deleteAccount(int id);
}
