import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

class AppDialog {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color iconColor = UiColors.sand,
    String buttonText = 'OK',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: UiShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: UiColors.muted,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      title: 'Success',
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF2E9E6B),
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context,
      title: 'Oops',
      message: message,
      icon: Icons.error_outline,
      iconColor: UiColors.danger,
    );
  }
}