import '../../domain/entities/budget_progress.dart';

class BudgetState {
  const BudgetState({required this.progresses});

  factory BudgetState.initial() {
    return const BudgetState(progresses: []);
  }

  final List<BudgetProgress> progresses;

  BudgetState copyWith({List<BudgetProgress>? progresses}) {
    return BudgetState(progresses: progresses ?? this.progresses);
  }
}
