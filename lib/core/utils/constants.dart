import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A8A); // Deep Blue
  static const Color secondary = Color(0xFFF59E0B); // Amber/Gold
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
}

class AppConstants {
  static const List<String> categories = [
    'الحديد',
    'الاسمنت',
    'الخشب',
    'الطوب',
    'البلاط',
    'الدهانات',
    'الأدوات الكهربائية',
    'أدوات السباكة',
    'الديكورات',
  ];

  static const List<String> units = [
    'كيس',
    'طن',
    'متر',
    'متر مربع',
    'قطعة',
  ];
}
