import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_error_notifier.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../domain/entities/profile.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_form_dialog.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  void _openEdit(BuildContext context, ProfileEntity profile) {
    final cubit = context.read<ProfileCubit>();
    showDialog(
      context: context,
      builder: (_) => ProfileFormDialog(
        initialName: profile.name,
        onSubmit: (result) => cubit.renameProfile(profile.id, result.name),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProfileEntity profile,
  ) async {
    final cubit = context.read<ProfileCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить профиль?'),
        content: Text(
          'Все транзакции, категории и счета профиля «${profile.name}» '
          'будут удалены.',
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
      try {
        await cubit.deleteProfile(profile.id);
      } catch (e) {
        showAppError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.profiles),
      appBar: AppBar(title: const Text('Профили')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.profiles.isEmpty) {
              return const EmptyState(
                icon: Icons.people_alt_rounded,
                title: 'Профилей ещё нет',
                message:
                    'Профиль — это изолированное пространство ваших финансов.',
              );
            }

            final canDelete = state.profiles.length > 1;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: state.profiles.length,
              itemBuilder: (context, index) {
                final profile = state.profiles[index];
                final isActive = profile.id == state.activeProfile?.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Material(
                    color: isActive
                        ? AppColors.brandContainer
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: isActive
                          ? null
                          : () => context.read<ProfileCubit>().switchProfile(
                              profile.id,
                            ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isActive
                                ? AppColors.brand
                                : AppColors.outline,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.brand
                                    : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isActive
                                        ? 'Активный профиль'
                                        : 'Нажмите для переключения',
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.brandDark
                                          : AppColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.brand,
                                  size: 22,
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.textTertiary,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEdit(context, profile);
                                } else if (value == 'delete') {
                                  _confirmDelete(context, profile);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 18),
                                      SizedBox(width: 10),
                                      Text('Переименовать'),
                                    ],
                                  ),
                                ),
                                if (!isActive && canDelete)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: AppColors.expense,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Удалить',
                                          style: TextStyle(
                                            color: AppColors.expense,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Профиль'),
      ),
    );
  }
}
