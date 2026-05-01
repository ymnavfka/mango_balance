import '../repositories/account_repository.dart';

class DeleteAccount {
  DeleteAccount(this.repository);

  final AccountRepository repository;

  Future<void> call(int id) async {
    await repository.deleteAccount(id);
  }
}
