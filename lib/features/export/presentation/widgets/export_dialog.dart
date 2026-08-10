import 'package:flutter/material.dart';

import '../../../../core/services/app_error_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/cubit/profile_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final Set<int> _selected = {};
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    final activeId = context.read<ProfileCubit>().state.activeProfile?.id;
    if (activeId != null) _selected.add(activeId);
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

  void _export(List<int> ids) {
    if (ids.isEmpty) {
      showAppNotice('Выберите хотя бы профиль');
      return;
    }
    if (_dateFrom != null && _dateTo != null && _dateFrom!.isAfter(_dateTo!)) {
      showAppNotice('Дата «С» не может быть позже даты «По»');
      return;
    }
    context.read<ExportCubit>().exportToXlsx(
      profileIds: ids,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  void _exportCurrent() {
    final activeId = context.read<ProfileCubit>().state.activeProfile?.id;
    if (activeId == null) {
      showAppNotice('Нет активного профиля');
      return;
    }
    setState(() {
      _selected
        ..clear()
        ..add(activeId);
    });
    _export([activeId]);
  }

  void _exportAll(List<ProfileEntity> profiles) {
    final ids = profiles.map((p) => p.id).toList();
    setState(() {
      _selected
        ..clear()
        ..addAll(ids);
    });
    _export(ids);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportCubit, ExportState>(
      listener: (context, state) {
        if (state.status == ExportStatus.success && state.result != null) {
          final r = state.result!;
          Navigator.of(context).pop();
          final where = r.profilesCount == 1
              ? 'профиля «${r.profileNames.first}»'
              : 'профилей: ${r.profilesCount}';
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Экспортировано ${r.transactionsCount} операций из $where'
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
          subtitle:
              'Полный бэкап: счета, категории, операции, бюджеты '
              'и регулярные платежи',
          loading: isBusy,
          primaryLabel: 'Экспортировать выбранные',
          onPrimary: isBusy ? null : () => _export(_selected.toList()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: isBusy ? null : _exportCurrent,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandContainer,
                        foregroundColor: AppColors.brandDark,
                      ),
                      child: const Text('Текущий профиль'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: isBusy ? null : () => _exportAll(profiles),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandContainer,
                        foregroundColor: AppColors.brandDark,
                      ),
                      child: const Text('Все профили'),
                    ),
                  ),
                ],
              ),
              const FormFieldLabel('Профили в бэкап'),
              ...profiles.map(
                (ProfileEntity p) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  visualDensity: VisualDensity.compact,
                  value: _selected.contains(p.id),
                  onChanged: isBusy
                      ? null
                      : (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(p.id);
                          } else {
                            _selected.remove(p.id);
                          }
                        }),
                  title: Text(p.name + (p.isActive ? ' (активный)' : '')),
                ),
              ),
              const FormFieldLabel('Диапазон дат операций (необязательно)'),
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
                'Диапазон дат ограничивает только операции. Счета, категории, '
                'бюджеты и регулярные платежи выгружаются полностью.',
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
