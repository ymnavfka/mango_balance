import 'package:flutter/material.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }

    widget.onSubmit(
      ProfileFormResult(name: name, includeStandardData: _includeStandardData),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Rename profile' : 'New profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Profile name'),
            autofocus: true,
          ),
          if (!widget.isEdit) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _includeStandardData,
              onChanged: (value) {
                setState(() {
                  _includeStandardData = value ?? false;
                });
              },
              title: const Text('Add standard categories and accounts'),
              subtitle: const Text(
                'If unchecked, only fallback categories and one default account will be created.',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
