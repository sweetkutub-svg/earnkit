import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/referral_link_service.dart';
import '../theme/ui_colors.dart';

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
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: UiColors.sand,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: UiColors.sand.withValues(alpha: 0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.card_giftcard,
                    size: 48, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text(
                _locked ? 'Invite Code Applied' : 'Got a Referral Code?',
                style: const TextStyle(
                    fontSize: 24,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _locked
                    ? "You joined through a friend's invite link.\nTap Next to continue."
                    : 'If a friend invited you, enter their code below.\nOtherwise, just tap Next.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: UiColors.muted,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                readOnly: _locked,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText:
                      _locked ? 'Referral Code' : 'Referral Code (Optional)',
                  prefixIcon: const Icon(Icons.card_giftcard_outlined),
                  suffixIcon: _locked
                      ? const Icon(Icons.lock, color: UiColors.sand)
                      : null,
                  helperText:
                      _locked ? 'Locked, applied from invite link' : null,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
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