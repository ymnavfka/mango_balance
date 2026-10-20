import '../goal.dart';
import '../repositories/goal_repository.dart';

class LoadGoalSnapshot {
  LoadGoalSnapshot(this.repository);

  final GoalRepository repository;

  Future<GoalSnapshot> call(int profileId, {DateTime? now}) {
    return repository.load(profileId, now: now);
  }
}
