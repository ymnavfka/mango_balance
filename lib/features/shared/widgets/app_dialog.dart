import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Единый каркас модального окна: заголовок, прокручиваемое тело и строка
/// действий. Используется всеми формами приложения, чтобы они выглядели
/// одинаково современно.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.secondaryLabel = 'Отмена',
    this.onSecondary,
    this.loading = false,
    this.maxWidth = 460,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final bool loading;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: media.size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Шапка.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: loading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Тело.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: child,
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(),
              ),
            // Действия.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : (onSecondary ?? () => Navigator.pop(context)),
                      child: Text(secondaryLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: loading ? null : onPrimary,
                      child: Text(primaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
