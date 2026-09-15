import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  Timer? _timer;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerified());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user comes back to the app (e.g. after clicking the email link
    // in their browser/email app), immediately check verification status
    // instead of waiting for the next 4-second timer tick.
    if (state == AppLifecycleState.resumed) {
      _checkVerified();
    }
  }

  Future<void> _checkVerified() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    final verified = await _authService.checkEmailVerified();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (verified) {
      _timer?.cancel();
      context.go('/home');
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    final error = await _authService.resendVerificationEmail();
    if (!mounted) return;
    setState(() => _isResending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(error == null ? 'Verification email sent again!' : error),
        backgroundColor: error == null ? AppColors.emerald : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Check your inbox',
                style: AppTextStyles.h1ScreenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'We sent a verification link to',
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTextStyles.h3CardTitle
                    .copyWith(color: AppColors.emerald),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.lightEmerald,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isChecking)
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emerald,
                        ),
                      )
                    else
                      const Icon(Icons.autorenew,
                          size: 14, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for verification...',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.emerald),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isResending ? null : _resendEmail,
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Resend Email'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _isChecking ? null : _checkVerified,
                child: const Text("I've verified — Check Now"),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Text(
                  'Back to Login',
                  style: TextStyle(color: AppColors.gray600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}