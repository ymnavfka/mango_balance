import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../../domain/entities/parsed_import.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось прочитать содержимое файла')),
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Выберите профиль')));
        return;
      }
      cubit.importIntoExisting(id);
    } else {
      final name = _newProfileNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите название профиля')),
        );
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
        if (state.status == ImportStatus.success && state.result != null) {
          final r = state.result!;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Импортировано ${r.importedTransactions} транзакций в профиль «${r.profileName}». '
                  '+${r.createdCategories} категорий, +${r.createdAccounts} счетов.'
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

        return AppDialog(
          title: 'Импорт из XLSX',
          loading: isBusy,
          primaryLabel: 'Импортировать',
          onPrimary: (state.status == ImportStatus.ready && !isBusy)
              ? _runImport
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
              const FormFieldLabel('Куда импортировать'),
              RadioGroup<_ImportTarget>(
                groupValue: _target,
                onChanged: isBusy
                    ? (_) {}
                    : (value) => setState(() => _target = value ?? _target),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RadioListTile<_ImportTarget>(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      value: _ImportTarget.existingProfile,
                      title: Text('В существующий профиль'),
                    ),
                    if (_target == _ImportTarget.existingProfile)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          top: 4,
                          bottom: 8,
                        ),
                        child: AppDropdownField<int>(
                          value: _selectedProfileId,
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
                          onChanged: isBusy
                              ? null
                              : (value) =>
                                    setState(() => _selectedProfileId = value),
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
              if (_target == _ImportTarget.newProfile)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _newProfileNameController,
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
                        value: _includeStandardData,
                        onChanged: isBusy
                            ? null
                            : (value) => setState(
                                () => _includeStandardData = value ?? false,
                              ),
                        title: const Text(
                          'Добавить стандартные категории и счета',
                          style: TextStyle(fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
  final ParsedImport? parsed;
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
            Builder(
              builder: (context) {
                final p = parsed!;
                return Text(
                  'Найдено: ${p.expenses.length} расходов, '
                  '${p.incomes.length} доходов, '
                  '${p.transfers.length} переводов'
                  '${p.skippedRows > 0 ? '. Пропущено ${p.skippedRows} строк.' : '.'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
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
