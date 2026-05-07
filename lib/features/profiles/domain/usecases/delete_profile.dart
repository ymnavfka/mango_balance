import '../repositories/profile_repository.dart';

class DeleteProfile {
  DeleteProfile(this.repository);

  final ProfileRepository repository;

  Future<void> call(int id) => repository.deleteProfile(id);
}
