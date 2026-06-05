import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Небольшая подпись над полем формы в едином стиле.
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key, this.top = AppSpacing.lg});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
