import '../repositories/profile_repository.dart';

class CreateProfile {
  CreateProfile(this.repository);

  final ProfileRepository repository;

  Future<int> call({required String name, required bool includeStandardData}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Название профиля обязательно');
    }

    return repository.createProfile(
      name: trimmed,
      includeStandardData: includeStandardData,
    );
  }
}
