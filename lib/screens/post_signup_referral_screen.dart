import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class PostSignupReferralScreen extends StatefulWidget {
  const PostSignupReferralScreen({super.key});

  @override
  State<PostSignupReferralScreen> createState() =>
      _PostSignupReferralScreenState();
}

class _PostSignupReferralScreenState extends State<PostSignupReferralScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    setState(() => _isLoading = true);

    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      final error = await _authService.linkReferralCode(code);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_authService.isEmailVerified) {
      context.go('/home');
    } else {
      context.go('/verify-email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard,
                    size: 48, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Got a Referral Code?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'If a friend invited you, enter their code below.\nOtherwise, just tap Next.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Referral Code (Optional)',
                  prefixIcon: Icon(Icons.card_giftcard_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}