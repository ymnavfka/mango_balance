import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../domain/entities/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/category_form_dialog.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  ({Color color, Color surface, IconData icon}) _style(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return (
          color: AppColors.income,
          surface: AppColors.incomeSurface,
          icon: Icons.south_west_rounded,
        );
      case TransactionType.expense:
        return (
          color: AppColors.expense,
          surface: AppColors.expenseSurface,
          icon: Icons.north_east_rounded,
        );
      case TransactionType.transfer:
        return (
          color: AppColors.transfer,
          surface: AppColors.transferSurface,
          icon: Icons.swap_horiz_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.categories),
      appBar: AppBar(title: const Text('Категории')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state.categories.isEmpty) {
              return const EmptyState(
                icon: Icons.category_rounded,
                title: 'Категорий ещё нет',
                message: 'Добавьте категории, чтобы группировать операции.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final style = _style(category.type);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: style.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(style.icon, color: style.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    category.type.label,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  if (category.isFallback) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Базовая',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!category.isFallback)
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            color: AppColors.textSecondary,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => CategoryFormDialog(
                                  initial: category,
                                  onSubmit: (updated) {
                                    context
                                        .read<CategoryCubit>()
                                        .updateCategory(updated);
                                  },
                                ),
                              );
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            category.isFallback
                                ? Icons.lock_rounded
                                : Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          color: category.isFallback
                              ? AppColors.textTertiary
                              : AppColors.expense,
                          onPressed: category.isFallback
                              ? null
                              : () => _confirmDelete(context, category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CategoryFormDialog(
              onSubmit: (category) {
                context.read<CategoryCubit>().addCategory(category);
              },
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Категория'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryEntity category,
  ) async {
    final cubit = context.read<CategoryCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text(
          'Операции категории «${category.name}» будут перепривязаны к '
          'базовой категории.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cubit.deleteCategory(category.id);
    }
  }
}
