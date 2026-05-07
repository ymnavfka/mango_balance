import '../entities/account.dart';
import '../repositories/account_repository.dart';

class WatchAccounts {
  WatchAccounts(this.repository);

  final AccountRepository repository;

  Stream<List<AccountEntity>> call(int profileId) {
    return repository.watchAccounts(profileId);
  }
}
