import 'package:flutter/material.dart';

import '../../../../core/services/app_error_notifier.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/form_field_label.dart';

class ProfileFormResult {
  const ProfileFormResult({
    required this.name,
    required this.includeStandardData,
  });

  final String name;
  final bool includeStandardData;
}

class ProfileFormDialog extends StatefulWidget {
  const ProfileFormDialog({
    super.key,
    this.initialName,
    required this.onSubmit,
  });

  final String? initialName;
  final void Function(ProfileFormResult result) onSubmit;

  bool get isEdit => initialName != null;

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  late final TextEditingController _nameController;
  bool _includeStandardData = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppNotice('Введите название профиля');
      return;
    }

    widget.onSubmit(
      ProfileFormResult(name: name, includeStandardData: _includeStandardData),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.isEdit ? 'Переименовать профиль' : 'Новый профиль',
      primaryLabel: widget.isEdit ? 'Сохранить' : 'Создать',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Название профиля', top: 0),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Например: Личные финансы',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          if (!widget.isEdit) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Стандартные категории и счета',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Иначе будут созданы только базовые сущности.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeStandardData,
                    onChanged: (value) =>
                        setState(() => _includeStandardData = value),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
