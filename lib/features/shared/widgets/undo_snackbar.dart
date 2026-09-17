import 'package:flutter/material.dart';

/// Длительность показа плашки удаления с возможностью отмены.
const Duration kUndoSnackBarDuration = Duration(seconds: 5);

/// Показывает плашку об удалении с обратным отсчётом 5→0, кружком прогресса
/// и автоматическим исчезновением по окончании отсчёта. Нажатие «Отменить»
/// вызывает [onUndo] и сразу скрывает плашку. При отключённых анимациях
/// показывается статическое сообщение на 15 секунд; для экранного диктора
/// сохраняется стандартное поведение SnackBar без автоматического скрытия.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final media = MediaQuery.of(context);
  final quiet = media.disableAnimations || media.accessibleNavigation;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        // Запасной предохранитель: фактическое закрытие выполняет сам виджет
        // по окончании отсчёта (см. _onStatusChanged). Встроенный авто-таймер
        // SnackBar ненадёжен, пока содержимое непрерывно анимируется.
        duration: quiet
            ? const Duration(seconds: 15)
            : kUndoSnackBarDuration + const Duration(seconds: 5),
        content: quiet
            ? Text(message)
            : _UndoCountdownContent(message: message),
        action: SnackBarAction(label: 'Отменить', onPressed: onUndo),
      ),
    );
}

class _UndoCountdownContent extends StatefulWidget {
  const _UndoCountdownContent({required this.message});

  final String message;

  @override
  State<_UndoCountdownContent> createState() => _UndoCountdownContentState();
}

class _UndoCountdownContentState extends State<_UndoCountdownContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kUndoSnackBarDuration,
    )..addStatusListener(_onStatusChanged);
    _controller.forward();
  }

  // По завершении отсчёта закрываем плашку сами — полагаться на
  // SnackBar.duration нельзя, пока содержимое непрерывно анимируется.
  void _onStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = kUndoSnackBarDuration.inSeconds;
    return Row(
      children: [
        Expanded(child: Text(widget.message)),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          height: 28,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final remaining = (totalSeconds * (1 - _controller.value))
                  .ceil()
                  .clamp(0, totalSeconds);
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1 - _controller.value,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '$remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
