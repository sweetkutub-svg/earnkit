import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';

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
    } else if (!_authService.isEmailVerified) {
      context.go('/verify-email');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockingScreen != null) return _blockingScreen!;

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