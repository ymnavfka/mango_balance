import '../repositories/goal_repository.dart';

class WatchGoalChanges {
  WatchGoalChanges(this.repository);

  final GoalRepository repository;

  Stream<void> call() => repository.watchChanges();
}
