import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

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
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius),
                              border: Border.all(color: AppColors.gray200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lock_outline,
                                        size: 14,
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
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius),
                              border: Border.all(color: AppColors.gray200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up,
                                        size: 14,
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
                    const SizedBox(height: AppSpacing.lg),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/withdraw'),
                        child: const Text('Withdraw Funds'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text('Transaction History',
                        style: AppTextStyles.h2SectionHeader),
                    const SizedBox(height: AppSpacing.md),

                    StreamBuilder<List<AppTransaction>>(
                      stream: firestoreService.streamTransactions(uid),
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
                                        Text(_labelForType(tx.type),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.emerald,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/wallet');
              break;
            case 2:
              context.go('/withdraw');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_rupee), label: 'Withdraw'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}