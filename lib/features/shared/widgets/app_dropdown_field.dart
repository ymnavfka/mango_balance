import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Современное поле-выпадающий список в едином стиле (заполненный фон,
/// скруглённые углы, плавающая подпись). Заменяет «голый» [DropdownButton].
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.icon,
    this.isDense = false,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final IconData? icon;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(AppRadius.md),
      icon: const Icon(Icons.expand_more_rounded),
      dropdownColor: AppColors.surface,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        isDense: isDense,
        prefixIcon: icon == null ? null : Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
