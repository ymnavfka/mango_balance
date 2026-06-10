import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/undo_snackbar.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/budget_state.dart';
import '../widgets/budget_form_dialog.dart';
import '../widgets/budget_progress_card.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  void _openForm(BuildContext context, {BudgetCubit? cubit, initial}) {
    final budgetCubit = cubit ?? context.read<BudgetCubit>();
    final categoryCubit = context.read<CategoryCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider<CategoryCubit>.value(
        value: categoryCubit,
        child: BudgetFormDialog(
          initial: initial,
          onSubmit: (budget) {
            if (initial == null) {
              budgetCubit.addBudget(budget);
            } else {
              budgetCubit.updateBudget(budget);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.budgets),
      appBar: AppBar(title: const Text('Бюджеты')),
      body: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, state) {
          if (state.progresses.isEmpty) {
            return const EmptyState(
              icon: Icons.savings_rounded,
              title: 'Бюджеты ещё не созданы',
              message:
                  'Задайте лимит трат на период, чтобы держать расходы '
                  'под контролем.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: state.progresses.length,
            itemBuilder: (context, index) {
              final progress = state.progresses[index];
              return Dismissible(
                key: ValueKey(progress.budget.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.expense,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) {
                  final cubit = context.read<BudgetCubit>();
                  final removed = progress.budget;
                  cubit.deleteBudget(removed.id);
                  showUndoSnackBar(
                    context,
                    message: 'Бюджет удалён',
                    onUndo: () => cubit.addBudget(removed),
                  );
                },
                child: BudgetProgressCard(
                  progress: progress,
                  onTap: () => _openForm(
                    context,
                    cubit: context.read<BudgetCubit>(),
                    initial: progress.budget,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Бюджет'),
      ),
    );
  }
}
