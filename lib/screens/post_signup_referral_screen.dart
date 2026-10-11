import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/referral_link_service.dart';
import '../theme/app_colors.dart';
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
  bool _locked = false; // true when the code came from an invite link

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  Future<void> _loadPending() async {
    final pending = await ReferralLinkService.getPending() ??
        await ReferralLinkService.detectFromClipboard();
    if (pending != null && mounted) {
      setState(() {
        _codeController.text = pending;
        _locked = true;
      });
    }
  }

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
    await ReferralLinkService.clearPending();

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
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard,
                    size: 48, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _locked ? 'Invite Code Applied' : 'Got a Referral Code?',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _locked
                    ? "You joined through a friend's invite link.\nTap Next to continue."
                    : 'If a friend invited you, enter their code below.\nOtherwise, just tap Next.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _codeController,
                readOnly: _locked,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText:
                      _locked ? 'Referral Code' : 'Referral Code (Optional)',
                  prefixIcon: const Icon(Icons.card_giftcard_outlined),
                  suffixIcon: _locked
                      ? const Icon(Icons.lock, color: AppColors.emerald)
                      : null,
                  helperText:
                      _locked ? 'Locked, applied from invite link' : null,
                  border: const OutlineInputBorder(),
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