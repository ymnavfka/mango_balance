import 'package:flutter/material.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
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
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add account' : 'Edit account'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Account name'),
      ),
      actions: [
        TextButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
