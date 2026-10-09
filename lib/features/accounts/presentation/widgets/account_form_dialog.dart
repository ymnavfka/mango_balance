import 'package:flutter/material.dart';

import '../../../../core/services/app_error_notifier.dart';

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
  late final TextEditingController _initialBalanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _initialBalanceController = TextEditingController(
      text: _formatInitialBalance(widget.initial?.initialBalance ?? 0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  // Пустое поле — для нулевого баланса (тогда виден хинт). Целое число без
  // дробной части, разделитель — запятая, как в остальном приложении.
  String _formatInitialBalance(double value) {
    if (value == 0) return '';
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return text.replaceAll('.', ',');
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppNotice('Введите название счёта');
      return;
    }

    final initialBalance =
        double.tryParse(
          _initialBalanceController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    widget.onSubmit(
      AccountEntity(
        id: widget.initial?.id ?? 0,
        name: name,
        isFallback: widget.initial?.isFallback ?? false,
        isArchived: widget.initial?.isArchived ?? false,
        initialBalance: initialBalance,
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
          const FormFieldLabel('Изначальный баланс'),
          TextField(
            controller: _initialBalanceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              helperText:
                  'Сумма на счёте до начала учёта. В доходы/расходы не входит.',
              helperMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
