import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/form_field_label.dart';
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

        return AppDialog(
          title: 'Экспорт в XLSX',
          loading: isBusy,
          primaryLabel: 'Экспортировать',
          onPrimary: isBusy ? null : _runExport,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FormFieldLabel('Профиль', top: 0),
              AppDropdownField<int>(
                value: _selectedProfileId,
                items: profiles
                    .map(
                      (ProfileEntity p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name + (p.isActive ? ' (активный)' : '')),
                      ),
                    )
                    .toList(),
                onChanged: isBusy
                    ? null
                    : (value) => setState(() => _selectedProfileId = value),
              ),
              const FormFieldLabel('Диапазон дат (необязательно)'),
              _DateRow(
                label: 'С',
                value: _dateFrom,
                onPick: isBusy ? null : () => _pickDate(from: true),
                onClear: isBusy || _dateFrom == null
                    ? null
                    : () => setState(() => _dateFrom = null),
                format: _formatDate,
              ),
              const SizedBox(height: 8),
              _DateRow(
                label: 'По',
                value: _dateTo,
                onPick: isBusy ? null : () => _pickDate(from: false),
                onClear: isBusy || _dateTo == null
                    ? null
                    : () => setState(() => _dateTo = null),
                format: _formatDate,
              ),
              const SizedBox(height: 10),
              const Text(
                'Оставьте поля пустыми, чтобы экспортировать все операции '
                'профиля.',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                          state.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
    final hasValue = value != null;
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.event_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue ? format(value!) : 'не задано',
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              if (hasValue)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
