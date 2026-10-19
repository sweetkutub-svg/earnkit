import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String message;
  const ForceUpdateScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.bg,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: UiShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
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
                child: const Icon(
                  Icons.system_update_alt,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Update Required',
                style: TextStyle(
                    fontSize: 21,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Phase 20 — open real Play Store / APK download link
                  },
                  child: const Text('Update Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}