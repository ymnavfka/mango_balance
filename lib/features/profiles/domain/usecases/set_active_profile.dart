import '../repositories/profile_repository.dart';

class SetActiveProfile {
  SetActiveProfile(this.repository);

  final ProfileRepository repository;

  Future<void> call(int id) => repository.setActiveProfile(id);
}
