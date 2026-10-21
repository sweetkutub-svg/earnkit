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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: UiShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                        color: UiColors.peach, shape: BoxShape.circle),
                    child: const Icon(Icons.build_circle_outlined,
                        size: 48, color: UiColors.ink),
                  ),
                  const SizedBox(height: 20),
                  const Text('Under Maintenance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 25,
                          color: UiColors.ink,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: UiColors.muted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}