import 'package:flutter/material.dart';
import 'ui_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    OutlineInputBorder inputBorder(Color c, [double w = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: UiColors.bg,
      primaryColor: UiColors.sand,
      colorScheme: ColorScheme.fromSeed(
        seedColor: UiColors.sand,
        primary: UiColors.sand,
        onPrimary: Colors.white,
        secondary: UiColors.mintDeep,
        error: UiColors.danger,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: UiColors.bg,
        foregroundColor: UiColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          color: UiColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UiColors.sand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: UiColors.disabled,
          disabledForegroundColor: Colors.white,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            return 5;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UiColors.sand,
          backgroundColor: Colors.white,
          side: const BorderSide(color: UiColors.sand, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UiColors.sand,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(const Color(0xFFE4E4E8)),
        focusedBorder: inputBorder(UiColors.sand, 1.8),
        errorBorder: inputBorder(UiColors.danger),
        focusedErrorBorder: inputBorder(UiColors.danger, 1.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: UiColors.sand,
        contentTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? UiColors.sand
                : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? UiColors.sand
                : UiColors.disabled),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: UiColors.sand,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEAEAEE),
        thickness: 1,
      ),
    );
  }
}