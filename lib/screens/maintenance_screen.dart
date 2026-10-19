import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

class MaintenanceScreen extends StatelessWidget {
  final String message;
  const MaintenanceScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: UiColors.lilac,
                  shape: BoxShape.circle,
                  boxShadow: UiShadows.card,
                ),
                child: const Icon(Icons.build_circle_outlined,
                    size: 56, color: UiColors.ink),
              ),
              const SizedBox(height: 28),
              const Text(
                'Under Maintenance',
                style: TextStyle(
                    fontSize: 26,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: UiColors.muted,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}