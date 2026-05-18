import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  int? _selectedProfileId;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileCubit>().state;
    _selectedProfileId = profileState.activeProfile?.id;
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = (from ? _dateFrom : _dateTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _dateFrom = DateTime(picked.year, picked.month, picked.day);
      } else {
        _dateTo = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _runExport() {
    final id = _selectedProfileId;
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите профиль')));
      return;
    }
    if (_dateFrom != null && _dateTo != null && _dateFrom!.isAfter(_dateTo!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дата «С» не может быть позже даты «По»')),
      );
      return;
    }

    context.read<ExportCubit>().exportToXlsx(
      profileId: id,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportCubit, ExportState>(
      listener: (context, state) {
        if (state.status == ExportStatus.success && state.result != null) {
          final r = state.result!;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Экспортировано ${r.exportedTransactions} транзакций из профиля «${r.profileName}»'
                  '${r.savedPath != null ? ' в ${r.savedPath}' : ''}',
                ),
              ),
            );
        }
        if (state.status == ExportStatus.cancelled) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final profiles = context.watch<ProfileCubit>().state.profiles;
        final isBusy = state.status == ExportStatus.working;

        return AlertDialog(
          title: const Text('Экспорт в XLSX'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Профиль',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedProfileId,
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
                      : (value) {
                          setState(() {
                            _selectedProfileId = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Диапазон дат (необязательно)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _DateRow(
                  label: 'С',
                  value: _dateFrom,
                  onPick: isBusy ? null : () => _pickDate(from: true),
                  onClear: isBusy || _dateFrom == null
                      ? null
                      : () => setState(() => _dateFrom = null),
                  format: _formatDate,
                ),
                _DateRow(
                  label: 'По',
                  value: _dateTo,
                  onPick: isBusy ? null : () => _pickDate(from: false),
                  onClear: isBusy || _dateTo == null
                      ? null
                      : () => setState(() => _dateTo = null),
                  format: _formatDate,
                ),
                const SizedBox(height: 4),
                Text(
                  'Оставьте оба поля пустыми, чтобы экспортировать все транзакции профиля.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
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
              onPressed: isBusy ? null : _runExport,
              child: const Text('Экспортировать'),
            ),
          ],
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
    required this.format,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label)),
          Expanded(child: Text(value == null ? '—' : format(value!))),
          TextButton(onPressed: onPick, child: const Text('Выбрать')),
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            tooltip: 'Сбросить',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
