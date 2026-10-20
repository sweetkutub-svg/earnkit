import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/ui_colors.dart';
import 'legal_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _handleGoogleSignUp() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the Terms & Privacy Policy')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      context.go('/post-signup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _toLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
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
          onTap: _toLogin,
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
                Text('Create\nAccount',
                    style: TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('Start earning with Earnkit',
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
                color: UiColors.lilac, shape: BoxShape.circle),
            child: const Icon(Icons.rocket_launch_outlined,
                size: 34, color: UiColors.ink),
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
        onTap: _isGoogleLoading ? null : _handleGoogleSignUp,
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
              const Text('Sign up with Google',
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

  Widget _termsRow() {
    TextStyle linkStyle() => const TextStyle(
        color: UiColors.sand,
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline);
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          activeColor: UiColors.sand,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (value) =>
              setState(() => _agreedToTerms = value ?? false),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: UiColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: linkStyle(),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            title: 'Terms of Service',
                            field: 'termsOfService',
                          ),
                        )),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: linkStyle(),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            title: 'Privacy Policy',
                            field: 'privacyPolicy',
                          ),
                        )),
                ),
              ],
            ),
          ),
        ),
      ],
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
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      decoration: _dec('Full Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 8),
                    _termsRow(),
                    const SizedBox(height: 8),
                    _primaryButton('Create Account',
                        _isLoading ? null : _handleSignup, _isLoading),
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
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _toLogin,
                  child: const Text('Already have an account? Login',
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