import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/ui_colors.dart';
import '../widgets/app_dialog.dart';
import 'legal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: UiColors.muted, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: UiColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: UiColors.bg,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: b(Colors.transparent, 0),
      enabledBorder: b(Colors.transparent, 0),
      focusedBorder: b(UiColors.sand, 1.5),
    );
  }

  Widget _consentText() {
    Widget link(String label, String title, String field) => GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LegalScreen(title: title, field: field),
          )),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: UiColors.sand,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
        );
    const t = TextStyle(
        fontSize: 12, color: UiColors.muted, fontWeight: FontWeight.w500);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('By continuing you agree to our ', style: t),
        link('Terms', 'Terms of Service', 'termsOfService'),
        const Text(' & ', style: t),
        link('Privacy Policy', 'Privacy Policy', 'privacyPolicy'),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      if (_authService.isEmailVerified) {
        context.go('/home');
      } else {
        context.go('/verify-email');
      }
    } else {
      AppDialog.showError(context, error);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final result = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.error == null) {
      if (result.isNewUser) {
        context.go('/post-signup');
      } else {
        context.go('/home');
      }
    } else {
      AppDialog.showError(context, result.error!);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter your email above first, then tap this')),
      );
      return;
    }
    final error = await _authService.resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            error == null ? 'Password reset email sent to $email' : error),
      ),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
  }

  Widget _circleBack() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: UiShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _back,
          child: const Icon(Icons.arrow_back_rounded,
              color: UiColors.ink, size: 22),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: UiColors.sand,
        borderRadius: BorderRadius.circular(32),
        boxShadow: UiShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Welcome\nBack',
                    style: TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('Login to continue earning',
                    style: TextStyle(
                        fontSize: 14,
                        color: UiColors.onSandSoft,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
                color: UiColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.savings_outlined,
                size: 36, color: UiColors.ink),
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

  Widget _googleButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isGoogleLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset('assets/images/google_logo.png',
                      height: 20, width: 20),
              const SizedBox(width: 10),
              const Text('Continue with Google',
                  style: TextStyle(
                      fontSize: 15,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: _circleBack()),
              const SizedBox(height: 18),
              _hero(),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: UiShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec('Email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _dec(
                        'Password',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: UiColors.muted),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        child: const Text('Forgot Password?',
                            style: TextStyle(
                                color: UiColors.sand,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _primaryButton(
                        'Login', _isLoading ? null : _handleLogin, _isLoading),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(child: Divider(color: UiColors.disabled)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR',
                        style: TextStyle(
                            fontSize: 12,
                            color: UiColors.muted,
                            fontWeight: FontWeight.w800)),
                  ),
                  Expanded(child: Divider(color: UiColors.disabled)),
                ],
              ),
              const SizedBox(height: 18),
              _googleButton(),
              const SizedBox(height: 18),
              _consentText(),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("Don't have an account? Sign up",
                      style: TextStyle(
                          color: UiColors.ink, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}