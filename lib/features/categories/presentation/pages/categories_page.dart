import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/archive_actions.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/category_form_dialog.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _showArchived = false;

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
      appBar: AppBar(
        title: Text(_showArchived ? 'Архив — категории' : 'Категории'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showArchived = !_showArchived),
            child: Text(_showArchived ? 'Активные' : 'Архив'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            final visible = state.categories
                .where((item) => item.isArchived == _showArchived)
                .toList();
            if (visible.isEmpty) {
              return EmptyState(
                icon: Icons.category_rounded,
                title: _showArchived ? 'Архив пуст' : 'Категорий ещё нет',
                message: _showArchived
                    ? 'Архивные объекты сохраняют историю и могут быть восстановлены.'
                    : 'Добавьте категории, чтобы группировать операции.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final category = visible[index];
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
                                    category.isArchived
                                        ? '${category.type.label} · В архиве'
                                        : category.type.label,
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
                        if (!category.isFallback)
                          ArchiveActions(
                            id: category.id,
                            name: category.name,
                            isAccount: false,
                            isArchived: category.isArchived,
                            onArchiveChanged: (value) =>
                                context.read<CategoryCubit>().updateCategory(
                                  category.copyWith(isArchived: value),
                                ),
                            onDelete: () => context
                                .read<CategoryCubit>()
                                .deleteCategory(category.id),
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
}
