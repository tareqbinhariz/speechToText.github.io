import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color primary = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color background = Color(0xFFF8FAFC);

  // Accent
  static const Color blueAccent = Colors.blueAccent;
  static const Color redAccent = Colors.redAccent;
  static const Color green = Colors.green;
  static const Color amber = Colors.amber;
  static const Color purple = Colors.purple;

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white60;
  static const Color textHint = Colors.white30;

  // Light mode text
  static const Color textPrimaryLight = Colors.black87;
  static const Color textSecondaryLight = Colors.black54;
  static const Color textHintLight = Colors.black38;

  // Card
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardLight = Colors.white;

  static Color statusColor(String status) {
    if (status.contains('❌') || status.contains('خطأ')) {
      return redAccent;
    } else if (status.contains('🎤') || status.contains('يستمع')) {
      return blueAccent;
    } else if (status.contains('✅') || status.contains('تم')) {
      return green;
    }
    return Colors.grey;
  }
}
