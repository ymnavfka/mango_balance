import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class WatchProfiles {
  WatchProfiles(this.repository);

  final ProfileRepository repository;

  Stream<List<ProfileEntity>> call() => repository.watchProfiles();
}
