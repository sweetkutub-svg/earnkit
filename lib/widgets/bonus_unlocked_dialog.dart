import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

class BonusUnlockedDialog {
  static void show(BuildContext context, int amount) {
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: UiColors.sand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: UiColors.sand.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.star_rounded,
                      size: 42, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text(
                  '🎉 Bonus Unlocked!',
                  style: TextStyle(
                      fontSize: 21,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: UiColors.mint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$amount Earnkit Points',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: UiColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your locked signup bonus has been added to your available balance!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                    child: const Text('Awesome!'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}