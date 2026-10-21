import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String message;
  const ForceUpdateScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                  decoration: BoxDecoration(
                    color: UiColors.sand,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: UiShadows.card,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                            color: UiColors.mint, shape: BoxShape.circle),
                        child: const Icon(Icons.system_update_alt,
                            size: 44, color: UiColors.ink),
                      ),
                      const SizedBox(height: 20),
                      const Text('Update Required',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: UiColors.onSandSoft,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  color: UiColors.sand,
                  borderRadius: BorderRadius.circular(40),
                  elevation: 5,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () {
                      // TODO: Phase 20 — open real Play Store / APK download link
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 17),
                      child: Center(
                        child: Text('Update Now',
                            style: TextStyle(
                                fontSize: 15.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}