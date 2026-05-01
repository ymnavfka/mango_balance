import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/category_form_dialog.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state.categories.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }

          return ListView.builder(
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return ListTile(
                title: Text(category.name),
                subtitle: Text(
                  '${category.type.name}${category.isFallback ? ' • Fallback' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!category.isFallback)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => CategoryFormDialog(
                              initial: category,
                              onSubmit: (updated) {
                                context.read<CategoryCubit>().updateCategory(
                                  updated,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        category.isFallback ? Icons.lock : Icons.delete,
                      ),
                      onPressed: category.isFallback
                          ? null
                          : () {
                              context.read<CategoryCubit>().deleteCategory(
                                category.id,
                              );
                            },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
