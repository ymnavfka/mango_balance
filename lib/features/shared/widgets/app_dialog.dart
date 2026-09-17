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
    final media = MediaQuery.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: media.size.height * 0.82,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // При клавиатуре или крупном тексте прокручивается вся форма:
            // неподвижная шапка не должна вытеснять поля и кнопки.
            final compact =
                constraints.maxHeight < 400 ||
                constraints.maxWidth < 280 ||
                media.textScaler.scale(14) > 21;
            final header = _header(context);
            final actions = _actions(context, stacked: compact);
            if (compact) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    header,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: child,
                    ),
                    if (loading) const LinearProgressIndicator(),
                    actions,
                  ],
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
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
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
    );
  }

  Widget _actions(BuildContext context, {required bool stacked}) {
    final secondary = OutlinedButton(
      onPressed: loading ? null : (onSecondary ?? () => Navigator.pop(context)),
      child: Text(secondaryLabel, textAlign: TextAlign.center),
    );
    final primary = FilledButton(
      onPressed: loading ? null : onPrimary,
      child: Text(primaryLabel, textAlign: TextAlign.center),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                secondary,
                const SizedBox(height: AppSpacing.md),
                primary,
              ],
            )
          : Row(
              children: [
                Expanded(child: secondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: primary),
              ],
            ),
    );
  }
}
