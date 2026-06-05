import 'package:flutter/material.dart';

/// Централизованная палитра приложения.
///
/// Семантические цвета (доход/расход/перевод) задаются явно и не зависят от
/// сгенерированной из seed-цвета схемы, чтобы они оставались одинаковыми на всех
/// экранах и хорошо читались.
class AppColors {
  AppColors._();

  // Бренд.
  static const Color brand = Color(0xFF4F46E5); // индиго
  static const Color brandDark = Color(0xFF4338CA);
  static const Color brandContainer = Color(0xFFEAEAFE);

  // Семантика финансовых операций.
  static const Color income = Color(0xFF16A34A); // зелёный
  static const Color incomeSurface = Color(0xFFE7F6EC);
  static const Color expense = Color(0xFFE11D48); // красный
  static const Color expenseSurface = Color(0xFFFCE7EC);
  static const Color transfer = Color(0xFF0EA5E9); // голубой
  static const Color transferSurface = Color(0xFFE2F4FD);

  // Статусы.
  static const Color warning = Color(0xFFF59E0B); // янтарь
  static const Color success = income;
  static const Color danger = expense;

  // Нейтральные поверхности.
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFEEF0F6);
  static const Color outline = Color(0xFFE3E6EE);

  // Текст.
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA1AE);

  /// Цвет суммы по знаку.
  static Color amount(double value) =>
      value < 0 ? expense : (value > 0 ? income : textPrimary);
}

/// Отступы единой сетки.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

/// Радиусы скругления.
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}
