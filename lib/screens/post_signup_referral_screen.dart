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

  InputDecoration _dec() {
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: _locked ? 'Referral Code' : 'Referral Code (Optional)',
      hintStyle: const TextStyle(
          color: UiColors.muted, fontWeight: FontWeight.w500),
      prefixIcon:
          const Icon(Icons.card_giftcard_outlined, color: UiColors.muted),
      suffixIcon: _locked
          ? const Icon(Icons.lock_outline, color: UiColors.sand)
          : null,
      helperText: _locked ? 'Locked, applied from invite link' : null,
      filled: true,
      fillColor: UiColors.bg,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: b(Colors.transparent, 0),
      enabledBorder: b(Colors.transparent, 0),
      focusedBorder: b(UiColors.sand, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                  decoration: BoxDecoration(
                    color: UiColors.sand,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: UiShadows.card,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: const BoxDecoration(
                            color: UiColors.lilac, shape: BoxShape.circle),
                        child: const Icon(Icons.card_giftcard,
                            size: 44, color: UiColors.ink),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _locked ? 'Invite Code Applied' : 'Got a Referral Code?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locked
                            ? "You joined through a friend's invite link.\nTap Next to continue."
                            : 'If a friend invited you, enter their code below.\nOtherwise, just tap Next.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: UiColors.onSandSoft,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form
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
                        controller: _codeController,
                        readOnly: _locked,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 2,
                            color: UiColors.ink,
                            fontWeight: FontWeight.w800),
                        decoration: _dec(),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color:
                            _isLoading ? UiColors.disabled : UiColors.sand,
                        borderRadius: BorderRadius.circular(40),
                        elevation: _isLoading ? 0 : 5,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: _isLoading ? null : _handleNext,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Next',
                                            style: TextStyle(
                                                fontSize: 15.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded,
                                            size: 20, color: Colors.white),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}