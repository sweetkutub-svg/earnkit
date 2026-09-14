import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final user = _authService.currentUser;

      if (user == null) {
        // No session — first time or logged out
        context.go('/onboarding');
      } else if (!_authService.isEmailVerified) {
        // Logged in but email/password user hasn't verified yet
        context.go('/verify-email');
      } else {
        // Already logged in and verified — skip straight to Home
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepTeal,
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Earnkit',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}