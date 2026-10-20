import '../repositories/goal_repository.dart';

class DeleteGoal {
  DeleteGoal(this.repository);

  final GoalRepository repository;

  Future<void> call(int id, int profileId) {
    return repository.delete(id, profileId);
  }
}
