import '../repositories/goal_repository.dart';

class CompleteGoal {
  CompleteGoal(this.repository);

  final GoalRepository repository;

  Future<void> call(int id, int profileId) {
    return repository.complete(id, profileId);
  }
}
