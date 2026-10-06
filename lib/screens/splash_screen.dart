import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();
  final _remoteConfigService = RemoteConfigService();
  Widget? _blockingScreen;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final config = await _remoteConfigService.fetchConfig();

    if (config.maintenanceMode) {
      if (mounted) {
        setState(() {
          _blockingScreen =
              MaintenanceScreen(message: config.maintenanceMessage);
        });
      }
      return;
    }

    final needsUpdate =
        await _remoteConfigService.isUpdateRequired(config.minRequiredVersion);
    if (needsUpdate) {
      if (mounted) {
        setState(() {
          _blockingScreen = ForceUpdateScreen(message: config.updateMessage);
        });
      }
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = _authService.currentUser;
    if (user == null) {
      context.go('/onboarding');
      return;
    }

    // Check ban status before anything else
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists && (userDoc.data()?['banned'] == true)) {
      await _authService.signOut();
      if (mounted) {
        setState(() {
          _blockingScreen = MaintenanceScreen(
            message:
                'Your account has been suspended. Contact support if you believe this is a mistake.',
          );
        });
      }
      return;
    }

    if (!_authService.isEmailVerified) {
      context.go('/verify-email');
    } else {
      context.go('/home');
    }
  }

      @override
  Widget build(BuildContext context) {
    if (_blockingScreen != null) return _blockingScreen!;

    return Scaffold(
      backgroundColor: AppColors.deepTeal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Image.asset(
                'assets/images/splash_mascot.png',
                width: 190,
                height: 190,
                errorBuilder: (_, __, ___) => const SizedBox(height: 190),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Earnkit',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Earning Mentor',
              style: GoogleFonts.caveat(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF5B301),
              ),
            ),
          ],
        ),
      ),
    );
  }
}