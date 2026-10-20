import '../goal.dart';
import '../repositories/goal_repository.dart';

class SaveGoal {
  SaveGoal(this.repository);

  final GoalRepository repository;

  Future<void> call(GoalPlan goal, {DateTime? now}) {
    return repository.save(goal, now: now);
  }
}
