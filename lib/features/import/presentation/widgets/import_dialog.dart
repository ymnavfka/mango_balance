import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
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

        return AlertDialog(
          title: const Text('Импорт из XLSX'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FileSection(
                  fileName: state.fileName,
                  parsed: state.parsed,
                  status: state.status,
                  onPick: isBusy ? null : _pickFile,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const Divider(height: 24),
                const Text(
                  'Куда импортировать',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioGroup<_ImportTarget>(
                  groupValue: _target,
                  onChanged: isBusy
                      ? (_) {}
                      : (value) {
                          setState(() {
                            _target = value ?? _target;
                          });
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RadioListTile<_ImportTarget>(
                        contentPadding: EdgeInsets.zero,
                        value: _ImportTarget.existingProfile,
                        title: Text('В существующий профиль'),
                      ),
                      if (_target == _ImportTarget.existingProfile)
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedProfileId,
                            items: profiles
                                .map(
                                  (ProfileEntity p) => DropdownMenuItem<int>(
                                    value: p.id,
                                    child: Text(
                                      p.name +
                                          (p.isActive ? ' (активный)' : ''),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: isBusy
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedProfileId = value;
                                    });
                                  },
                          ),
                        ),
                      const RadioListTile<_ImportTarget>(
                        contentPadding: EdgeInsets.zero,
                        value: _ImportTarget.newProfile,
                        title: Text('Создать новый профиль'),
                      ),
                    ],
                  ),
                ),
                if (_target == _ImportTarget.newProfile)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _newProfileNameController,
                          decoration: const InputDecoration(
                            labelText: 'Название нового профиля',
                          ),
                          enabled: !isBusy,
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _includeStandardData,
                          onChanged: isBusy
                              ? null
                              : (value) {
                                  setState(() {
                                    _includeStandardData = value ?? false;
                                  });
                                },
                          title: const Text(
                            'Добавить стандартные категории и счета',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isBusy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isBusy ? null : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: (state.status == ImportStatus.ready && !isBusy)
                  ? _runImport
                  : null,
              child: const Text('Импортировать'),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fileName ?? 'Файл не выбран',
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.attach_file),
              label: const Text('Выбрать файл'),
            ),
          ],
        ),
        if (parsed != null && status == ImportStatus.ready)
          Builder(
            builder: (context) {
              final p = parsed!;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Найдено: ${p.expenses.length} расходов, '
                  '${p.incomes.length} доходов, '
                  '${p.transfers.length} переводов'
                  '${p.skippedRows > 0 ? '. Пропущено ${p.skippedRows} строк.' : '.'}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              );
            },
          ),
      ],
    );
  }
}
