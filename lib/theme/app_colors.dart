import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary & Accents
  static const Color deepTeal = Color(0xFF064E3B);
  static const Color emerald = Color(0xFF047857);
  static const Color lightEmerald = Color(0xFFECFDF5);
  static const Color gold = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // Semantic Feedback
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Gradient used on balance cards / primary buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [deepTeal, emerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}