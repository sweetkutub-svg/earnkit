import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/ui_colors.dart';

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
        backgroundColor: error == null ? UiColors.sand : UiColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: UiColors.sand,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: UiColors.sand.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Check your inbox',
                style: TextStyle(
                    fontSize: 28,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'We sent a verification link to',
                style: TextStyle(
                    fontSize: 14,
                    color: UiColors.muted,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                    fontSize: 15,
                    color: UiColors.sand,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: UiColors.mint,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: UiShadows.card,
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
                          color: UiColors.ink,
                        ),
                      )
                    else
                      const Icon(Icons.autorenew,
                          size: 14, color: UiColors.ink),
                    const SizedBox(width: 8),
                    const Text(
                      'Waiting for verification...',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: UiColors.ink,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isChecking ? null : _checkVerified,
                child: const Text("I've verified — Check Now"),
              ),
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: UiColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}