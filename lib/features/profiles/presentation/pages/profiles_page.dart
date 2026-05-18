import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_form_dialog.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.profiles),
      appBar: AppBar(title: const Text('Профили')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.profiles.isEmpty) {
            return const Center(child: Text('Профилей ещё нет'));
          }

          return ListView.builder(
            itemCount: state.profiles.length,
            itemBuilder: (context, index) {
              final profile = state.profiles[index];
              final isActive = profile.id == state.activeProfile?.id;
              return ListTile(
                leading: Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(profile.name),
                subtitle: Text(
                  isActive ? 'Активный' : 'Нажмите для переключения',
                ),
                onTap: isActive
                    ? null
                    : () {
                        context.read<ProfileCubit>().switchProfile(profile.id);
                      },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        final cubit = context.read<ProfileCubit>();
                        showDialog(
                          context: context,
                          builder: (_) => ProfileFormDialog(
                            initialName: profile.name,
                            onSubmit: (result) {
                              cubit.renameProfile(profile.id, result.name);
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isActive || state.profiles.length <= 1
                            ? Icons.lock
                            : Icons.delete,
                      ),
                      onPressed: isActive || state.profiles.length <= 1
                          ? null
                          : () async {
                              final cubit = context.read<ProfileCubit>();
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Удалить профиль?'),
                                  content: Text(
                                    'Все транзакции, категории и счета профиля «${profile.name}» будут удалены.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                try {
                                  await cubit.deleteProfile(profile.id);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              }
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
          final cubit = context.read<ProfileCubit>();
          showDialog(
            context: context,
            builder: (_) => ProfileFormDialog(
              onSubmit: (result) {
                cubit.createProfile(
                  name: result.name,
                  includeStandardData: result.includeStandardData,
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
