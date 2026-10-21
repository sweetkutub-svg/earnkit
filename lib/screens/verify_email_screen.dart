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

  Widget _hero(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
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
            child: const Icon(Icons.mark_email_unread_outlined,
                size: 46, color: UiColors.ink),
          ),
          const SizedBox(height: 20),
          const Text('Check your inbox',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('We sent a verification link to',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: UiColors.onSandSoft,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: UiShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                color: UiColors.lilac, shape: BoxShape.circle),
            child: _isChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: UiColors.ink),
                  )
                : const Icon(Icons.autorenew,
                    size: 20, color: UiColors.ink),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waiting for verification...',
                    style: TextStyle(
                        fontSize: 14.5,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Open the link in your email, then come back here.',
                    style: TextStyle(
                        fontSize: 12,
                        color: UiColors.muted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap, bool loading) {
    return Material(
      color: onTap == null ? UiColors.disabled : UiColors.sand,
      borderRadius: BorderRadius.circular(40),
      elevation: onTap == null ? 0 : 5,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(label,
                    style: const TextStyle(
                        fontSize: 15.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(email),
                const SizedBox(height: 16),
                _statusCard(),
                const SizedBox(height: 22),
                _primaryButton('Resend Email',
                    _isResending ? null : _resendEmail, _isResending),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isChecking ? null : _checkVerified,
                  child: const Text("I've verified — Check Now",
                      style: TextStyle(
                          color: UiColors.sand, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () async {
                    await _authService.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('Back to Login',
                      style: TextStyle(
                          color: UiColors.muted, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}