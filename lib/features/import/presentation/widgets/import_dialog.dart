import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../../../../core/services/app_error_notifier.dart';
import '../../domain/entities/parsed_file.dart';
import '../cubit/import_cubit.dart';
import '../cubit/import_state.dart';

enum _ImportTarget { existingProfile, newProfile }

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  _ImportTarget _target = _ImportTarget.existingProfile;
  int? _selectedProfileId;
  final TextEditingController _newProfileNameController =
      TextEditingController();
  bool _includeStandardData = true;

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileCubit>().state;
    _selectedProfileId = profileState.activeProfile?.id;
  }

  @override
  void dispose() {
    _newProfileNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      showAppNotice('Не удалось прочитать содержимое файла');
      return;
    }

    if (!mounted) return;
    await context.read<ImportCubit>().loadFile(
      fileName: file.name,
      bytes: bytes,
    );
  }

  void _runImport() {
    final cubit = context.read<ImportCubit>();
    if (_target == _ImportTarget.existingProfile) {
      final id = _selectedProfileId;
      if (id == null) {
        showAppNotice('Выберите профиль');
        return;
      }
      cubit.importIntoExisting(id);
    } else {
      final name = _newProfileNameController.text.trim();
      if (name.isEmpty) {
        showAppNotice('Введите название профиля');
        return;
      }
      cubit.importIntoNewProfile(
        name: name,
        includeStandardData: _includeStandardData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportCubit, ImportState>(
      listener: (context, state) {
        if (state.status != ImportStatus.success) return;
        Navigator.of(context).pop();
        final messenger = ScaffoldMessenger.of(context)..clearSnackBars();

        final restore = state.restoreResult;
        if (restore != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Восстановлено профилей: ${restore.createdProfiles} '
                '(${restore.profileNames.join(', ')}). '
                '${restore.importedTransactions} операций, '
                '${restore.createdBudgets} бюджетов, '
                '${restore.createdRecurring} регулярных.',
              ),
            ),
          );
          return;
        }

        final r = state.result;
        if (r != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Импортировано ${r.importedTransactions} транзакций в профиль '
                '«${r.profileName}». +${r.createdCategories} категорий, '
                '+${r.createdAccounts} счетов.'
                '${r.skippedRows > 0 ? ' Пропущено ${r.skippedRows} строк.' : ''}',
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final profiles = context.watch<ProfileCubit>().state.profiles;
        final isBusy =
            state.status == ImportStatus.parsing ||
            state.status == ImportStatus.importing;
        final isBackup = state.isBackup;
        final canRun = state.status == ImportStatus.ready && !isBusy;

        return AppDialog(
          title: isBackup ? 'Восстановление из бэкапа' : 'Импорт из XLSX',
          loading: isBusy,
          primaryLabel: isBackup ? 'Восстановить' : 'Импортировать',
          onPrimary: canRun
              ? (isBackup
                    ? () => context.read<ImportCubit>().restoreBackup()
                    : _runImport)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FileSection(
                fileName: state.fileName,
                parsed: state.parsed,
                status: state.status,
                onPick: isBusy ? null : _pickFile,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 10),
                _ErrorBox(state.errorMessage!),
              ],
              if (isBackup)
                _BackupTargetInfo(
                  count: state.parsed?.backup?.profilesCount ?? 0,
                )
              else
                _LegacyTargetSection(
                  target: _target,
                  onTargetChanged: isBusy
                      ? null
                      : (value) => setState(() => _target = value),
                  profiles: profiles,
                  selectedProfileId: _selectedProfileId,
                  onProfileChanged: isBusy
                      ? null
                      : (value) => setState(() => _selectedProfileId = value),
                  newProfileNameController: _newProfileNameController,
                  includeStandardData: _includeStandardData,
                  onIncludeStandardChanged: isBusy
                      ? null
                      : (value) => setState(() => _includeStandardData = value),
                  isBusy: isBusy,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BackupTargetInfo extends StatelessWidget {
  const _BackupTargetInfo({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormFieldLabel('Что произойдёт'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.restore_rounded,
                color: AppColors.brandDark,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count ${_profilesWord(count)} будут добавлены как новые — '
                  'существующие данные не затрагиваются. При совпадении названий '
                  'к имени добавится номер (личный → личный2).',
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _profilesWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'профиль';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'профиля';
    }
    return 'профилей';
  }
}

class _LegacyTargetSection extends StatelessWidget {
  const _LegacyTargetSection({
    required this.target,
    required this.onTargetChanged,
    required this.profiles,
    required this.selectedProfileId,
    required this.onProfileChanged,
    required this.newProfileNameController,
    required this.includeStandardData,
    required this.onIncludeStandardChanged,
    required this.isBusy,
  });

  final _ImportTarget target;
  final ValueChanged<_ImportTarget>? onTargetChanged;
  final List<ProfileEntity> profiles;
  final int? selectedProfileId;
  final ValueChanged<int?>? onProfileChanged;
  final TextEditingController newProfileNameController;
  final bool includeStandardData;
  final ValueChanged<bool>? onIncludeStandardChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormFieldLabel('Куда импортировать'),
        RadioGroup<_ImportTarget>(
          groupValue: target,
          onChanged: onTargetChanged == null
              ? (_) {}
              : (value) => onTargetChanged!(value ?? target),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RadioListTile<_ImportTarget>(
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                value: _ImportTarget.existingProfile,
                title: Text('В существующий профиль'),
              ),
              if (target == _ImportTarget.existingProfile)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
                  child: AppDropdownField<int>(
                    value: selectedProfileId,
                    isDense: true,
                    items: profiles
                        .map(
                          (ProfileEntity p) => DropdownMenuItem<int>(
                            value: p.id,
                            child: Text(
                              p.name + (p.isActive ? ' (активный)' : ''),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onProfileChanged,
                  ),
                ),
              const RadioListTile<_ImportTarget>(
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                value: _ImportTarget.newProfile,
                title: Text('Создать новый профиль'),
              ),
            ],
          ),
        ),
        if (target == _ImportTarget.newProfile)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: newProfileNameController,
                  enabled: !isBusy,
                  decoration: const InputDecoration(
                    hintText: 'Название нового профиля',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  visualDensity: VisualDensity.compact,
                  value: includeStandardData,
                  onChanged: onIncludeStandardChanged == null
                      ? null
                      : (value) => onIncludeStandardChanged!(value ?? false),
                  title: const Text(
                    'Добавить стандартные категории и счета',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FileSection extends StatelessWidget {
  const _FileSection({
    required this.fileName,
    required this.parsed,
    required this.status,
    required this.onPick,
  });

  final String? fileName;
  final ParsedFile? parsed;
  final ImportStatus status;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.income,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName ?? 'Файл не выбран',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: hasFile
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onPick,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: AppColors.brandContainer,
                  foregroundColor: AppColors.brandDark,
                ),
                child: const Text('Выбрать'),
              ),
            ],
          ),
          if (parsed != null && status == ImportStatus.ready) ...[
            const SizedBox(height: 10),
            Text(
              _summary(parsed!),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _summary(ParsedFile parsed) {
    final backup = parsed.backup;
    if (backup != null) {
      return 'Полный бэкап: ${backup.profilesCount} профилей, '
          '${backup.transactionsCount} операций, '
          '${backup.budgetsCount} бюджетов, '
          '${backup.recurringCount} регулярных.';
    }
    final p = parsed.legacy!;
    return 'Найдено: ${p.expenses.length} расходов, '
        '${p.incomes.length} доходов, '
        '${p.transfers.length} переводов'
        '${p.skippedRows > 0 ? '. Пропущено ${p.skippedRows} строк.' : '.'}';
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.expenseSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.expense,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.expense, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
