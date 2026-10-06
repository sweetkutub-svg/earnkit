import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/wallet_summary_service.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _authService = AuthService();
  final _summaryService = WalletSummaryService();
  final _upiController = TextEditingController();

  WalletSummary? _summary;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    final summary = await _summaryService.fetchSummary(uid);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  void _handleWithdrawTap() {
    final summary = _summary;
    if (summary == null) return;

    if (!summary.isEligible) {
      AppDialog.show(
        context,
        title: 'Not Eligible Yet',
        message:
            'You need ${summary.pointsNeeded} more Earnkit Points to unlock withdrawal.\n\n'
            'Once you reach ${summary.minWithdrawalPoints} points, they\'ll convert to ₹, '
            'and any unlocked bonus (₹${summary.unlockedBonus}) will be added on top. Keep watching ads!',
        icon: Icons.hourglass_empty,
        iconColor: AppColors.warningAmber,
      );
      return;
    }

    _showWithdrawForm(summary);
  }

  void _showWithdrawForm(WalletSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirm Withdrawal',
                        style: AppTextStyles.h2SectionHeader),
                    const SizedBox(height: AppSpacing.md),
                    Text('You will receive',
                        style: AppTextStyles.bodyText),
                    Text('₹${summary.totalWithdrawable.toStringAsFixed(2)}',
                        style: AppTextStyles.displayCurrency),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _upiController,
                      decoration: const InputDecoration(
                        labelText: 'Your UPI ID',
                        hintText: 'example@upi',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                final upiId = _upiController.text.trim();
                                if (upiId.isEmpty || !upiId.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a valid UPI ID')));
                                  return;
                                }
                                setModalState(() => _isSubmitting = true);
                                final uid = _authService.currentUser?.uid;
                                final result =
                                    await _summaryService.submitWithdrawal(
                                        uid: uid!, upiId: upiId);
                                setModalState(() => _isSubmitting = false);

                                if (!context.mounted) return;
                                Navigator.of(context).pop();

                                if (result['success'] == true) {
                                  AppDialog.showSuccess(context,
                                      'Withdrawal request submitted! It will be processed soon.');
                                  _loadSummary();
                                } else {
                                  AppDialog.showError(context,
                                      result['error'] ?? 'Request failed');
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Confirm'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Could not load wallet data'),
                      TextButton(
                          onPressed: _loadSummary,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSummary,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Balance',
                                style: AppTextStyles.bodyText
                                    .copyWith(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text('${_summary!.points} Earnkit Points',
                                style: AppTextStyles.h1ScreenTitle
                                    .copyWith(color: Colors.white)),
                            if (_summary!.unlockedBonus > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+ ₹${_summary!.unlockedBonus} bonus ready',
                                style: AppTextStyles.caption
                                    .copyWith(color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: _summary!.isEligible
                              ? AppColors.lightEmerald
                              : AppColors.gray100,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _summary!.isEligible
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              color: _summary!.isEligible
                                  ? AppColors.emerald
                                  : AppColors.gray600,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _summary!.isEligible
                                    ? 'You\'re eligible to withdraw ₹${_summary!.totalWithdrawable.toStringAsFixed(2)}'
                                    : 'Reach ${_summary!.minWithdrawalPoints} points to unlock withdrawal (${_summary!.pointsNeeded} more needed)',
                                style: AppTextStyles.bodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleWithdrawTap,
                          child: const Text('Withdraw Now'),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
} 