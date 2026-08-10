import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/shared/theme/app_colors.dart';

/// Навигатор и мессенджер верхнего уровня. Оверлей навигатора используется, чтобы
/// показывать сообщения ПОВЕРХ диалогов и bottom sheet'ов (обычный
/// ScaffoldMessenger рисует их под модальными окнами, и они не видны).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Ошибка (красный тост) — причина сбоя действия.
void showAppError(Object error) => _showToast(_humanize(error), isError: true);

/// Подсказка/валидация (тёмный тост) — например «Выберите категорию».
void showAppNotice(String message) => _showToast(message, isError: false);

OverlayEntry? _current;

void _showToast(String message, {required bool isError}) {
  final overlay = rootNavigatorKey.currentState?.overlay;
  if (overlay == null) {
    // До готовности навигатора — запасной путь через мессенджер.
    rootScaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
    return;
  }

  _removeCurrent();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToast(
      message: message,
      isError: isError,
      onRemove: () {
        if (identical(_current, entry)) _current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

void _removeCurrent() {
  final entry = _current;
  _current = null;
  if (entry != null && entry.mounted) entry.remove();
}

String _humanize(Object error) {
  var text = error.toString().trim();
  for (final prefix in const ['Exception: ', 'Ошибка: ']) {
    if (text.startsWith(prefix)) text = text.substring(prefix.length).trim();
  }
  if (text.isEmpty) return 'Произошла ошибка';
  return 'Ошибка: $text';
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.isError,
    required this.onRemove,
  });

  final String message;
  final bool isError;
  final VoidCallback onRemove;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(seconds: 4), _hide);
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (mounted) {
      try {
        await _controller.reverse();
      } catch (_) {
        // Контроллер мог быть уничтожен — игнорируем.
      }
    }
    widget.onRemove();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final color = widget.isError ? AppColors.expense : AppColors.textPrimary;
    final icon = widget.isError
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return Positioned(
      top: media.padding.top + AppSpacing.sm,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.35),
                end: Offset.zero,
              ).animate(curved),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: color,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: _hide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
