import '../repositories/profile_repository.dart';

class RenameProfile {
  RenameProfile(this.repository);

  final ProfileRepository repository;

  Future<void> call(int id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Название профиля обязательно');
    }
    return repository.renameProfile(id, trimmed);
  }
}
