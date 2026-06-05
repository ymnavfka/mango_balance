import 'package:flutter/material.dart';

import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/form_field_label.dart';
import '../../domain/entities/account.dart';

class AccountFormDialog extends StatefulWidget {
  const AccountFormDialog({super.key, this.initial, required this.onSubmit});

  final AccountEntity? initial;
  final void Function(AccountEntity account) onSubmit;

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите название счёта')));
      return;
    }

    widget.onSubmit(
      AccountEntity(
        id: widget.initial?.id ?? 0,
        name: name,
        isFallback: widget.initial?.isFallback ?? false,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.initial == null ? 'Новый счёт' : 'Редактирование счёта',
      primaryLabel: widget.initial == null ? 'Добавить' : 'Сохранить',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormFieldLabel('Название счёта', top: 0),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Например: Дебетовая карта',
              prefixIcon: Icon(Icons.credit_card_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
