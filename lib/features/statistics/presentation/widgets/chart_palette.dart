import 'package:flutter/material.dart';

class ChartPalette {
  static const List<Color> _palette = [
    Color(0xFF4FC3F7),
    Color(0xFFFFB74D),
    Color(0xFFAED581),
    Color(0xFFBA68C8),
    Color(0xFFE57373),
    Color(0xFF4DB6AC),
    Color(0xFFFFD54F),
    Color(0xFF7986CB),
  ];

  static const Color other = Color(0xFFB0BEC5);

  static Color colorAt(int index) {
    return _palette[index % _palette.length];
  }
}
