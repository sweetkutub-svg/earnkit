import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/unlock_progress.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/banner_ad_widget.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.adWatched:
        return Icons.play_circle_outline;
      case TransactionType.taskCompleted:
        return Icons.task_alt;
      case TransactionType.referralBonus:
        return Icons.people_outline;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.bonusUnlocked:
        return Icons.star_outline;
    }
  }

  String _labelForType(TransactionType type) {
    switch (type) {
      case TransactionType.adWatched:
        return 'Ad Watched';
      case TransactionType.taskCompleted:
        return 'Task Completed';
      case TransactionType.referralBonus:
        return 'Referral Bonus';
      case TransactionType.withdrawal:
        return 'Withdrawal Sent';
      case TransactionType.bonusUnlocked:
        return 'Bonus Unlocked!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final uid = authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<AppUser?>(
              stream: firestoreService.streamUserData(uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = userSnapshot.data;
                if (user == null) {
                  return const Center(child: Text('User data not found'));
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Balance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius),
                        border: Border.all(color: AppColors.gray200),
boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance',
                              style: AppTextStyles.bodyText),
                          const SizedBox(height: 8),
                          Text(
                            '${user.walletBalance} Earnkit Points',
                            style: AppTextStyles.h1ScreenTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Locked + Lifetime row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius),
                              border: Border.all(color: AppColors.gray200),
boxShadow: AppShadows.soft,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lock_outline,
                                        size: 13,
                                        color: AppColors.gray600),
                                    const SizedBox(width: 4),
                                    Text('Locked',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('₹${user.lockedBonus}',
                                    style: AppTextStyles.h3CardTitle),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.amberLight,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.card_giftcard,
                                        size: 13, color: AppColors.gold),
                                    const SizedBox(width: 4),
                                    Text('Bonus',
                                        style: AppTextStyles.caption
                                            .copyWith(color: AppColors.gold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('₹${user.unlockedBonus}',
                                    style: AppTextStyles.h3CardTitle
                                        .copyWith(color: AppColors.gold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius),
                              border: Border.all(color: AppColors.gray200),
boxShadow: AppShadows.soft,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up,
                                        size: 13,
                                        color: AppColors.gray600),
                                    const SizedBox(width: 4),
                                    Text('Lifetime',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${user.walletBalance} Pts',
                                  style: AppTextStyles.h3CardTitle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.lockedBonus > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      UnlockProgress(adPoints: user.adPoints),
                    ],
                    if (user.unlockedBonus > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.lightEmerald,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: Text(
                          '₹${user.unlockedBonus} bonus unlocked — it will be added to your withdrawal total once you\'re eligible to withdraw.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.emerald),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/withdraw'),
                        child: const Text('Withdraw Funds'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const BannerAdWidget(),

                    Text('Withdrawal History',
                        style: AppTextStyles.h2SectionHeader),
                    const SizedBox(height: AppSpacing.md),

                    StreamBuilder<List<WithdrawalRequest>>(
                      stream: firestoreService.streamWithdrawals(uid),
                      builder: (context, wSnapshot) {
                        final withdrawals = wSnapshot.data ?? [];

                        if (withdrawals.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: withdrawals.map((w) {
                            Color statusColor;
                            String statusLabel;
                            switch (w.status) {
                              case WithdrawalStatus.paid:
                                statusColor = AppColors.successGreen;
                                statusLabel = 'Paid';
                                break;
                              case WithdrawalStatus.approved:
                                statusColor = AppColors.infoBlue;
                                statusLabel = 'Approved';
                                break;
                              case WithdrawalStatus.rejected:
                                statusColor = AppColors.errorRed;
                                statusLabel = 'Rejected';
                                break;
                              case WithdrawalStatus.pending:
                                statusColor = AppColors.warningAmber;
                                statusLabel = 'Pending';
                                break;
                            }
                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radius),
                                border:
                                    Border.all(color: AppColors.gray200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('₹${w.amount.toStringAsFixed(2)}',
                                            style:
                                                AppTextStyles.h3CardTitle),
                                        Text(
                                          w.requestedAt != null
                                              ? DateFormat('MMM d, h:mm a')
                                                  .format(w.requestedAt!)
                                              : 'Just now',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text('Transaction History',
                        style: AppTextStyles.h2SectionHeader),
                    const SizedBox(height: AppSpacing.md),

                    StreamBuilder<List<AppTransaction>>(
                      stream: firestoreService.streamRecentTransactions(uid),
                      builder: (context, txSnapshot) {
                        if (txSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final transactions = txSnapshot.data ?? [];

                        if (transactions.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Center(
                              child: Text(
                                'No transactions yet.\nWatch an ad to get started!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyText,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: transactions.map((tx) {
                            final isNegative = tx.amount < 0;
                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              padding:
                                  const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radius),
                                border:
                                    Border.all(color: AppColors.gray200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightEmerald,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _iconForType(tx.type),
                                      color: AppColors.emerald,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text((tx.type == TransactionType.taskCompleted && tx.taskTitle.isNotEmpty ? tx.taskTitle : _labelForType(tx.type)),
                                            style:
                                                AppTextStyles.h3CardTitle),
                                        Text(
                                          tx.timestamp != null
                                              ? DateFormat(
                                                      'MMM d, h:mm a')
                                                  .format(tx.timestamp!)
                                              : 'Just now',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isNegative ? '' : '+'}${tx.amount}',
                                    style: AppTextStyles.h3CardTitle.copyWith(
                                      color: isNegative
                                          ? AppColors.errorRed
                                          : AppColors.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}