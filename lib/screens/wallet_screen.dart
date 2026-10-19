import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/unlock_progress.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../theme/ui_colors.dart';

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

  Widget _title(String text) => Text(text,
      style: const TextStyle(
          fontSize: 20, color: UiColors.ink, fontWeight: FontWeight.w800));

  Widget _stat({
    required Color color,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: UiShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: UiColors.ink),
            ),
            const SizedBox(height: 14),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 17,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF55555A),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _listCard({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: UiShadows.card,
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final uid = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        bottom: false,
        child: uid == null
            ? const Center(child: Text('Not logged in'))
            : StreamBuilder<AppUser?>(
                stream: firestoreService.streamUserData(uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user = userSnapshot.data;
                  if (user == null) {
                    return const Center(child: Text('User data not found'));
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    children: [
                      const Text('Wallet',
                          style: TextStyle(
                              fontSize: 30,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),

                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                        decoration: BoxDecoration(
                          color: UiColors.sand,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: UiShadows.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available balance',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: UiColors.onSandSoft,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${user.walletBalance}',
                                    style: const TextStyle(
                                        fontSize: 48,
                                        height: 1,
                                        color: UiColors.onSand,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: Text('Earnkit Points',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: UiColors.onSandSoft,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _stat(
                            color: UiColors.lilac,
                            icon: Icons.lock_outline,
                            label: 'Locked',
                            value: '₹${user.lockedBonus}',
                          ),
                          const SizedBox(width: 10),
                          _stat(
                            color: UiColors.peach,
                            icon: Icons.card_giftcard,
                            label: 'Bonus',
                            value: '₹${user.unlockedBonus}',
                          ),
                          const SizedBox(width: 10),
                          _stat(
                            color: UiColors.mint,
                            icon: Icons.trending_up,
                            label: 'Ad Points',
                            value: '${user.adPoints}',
                          ),
                        ],
                      ),

                      if (user.lockedBonus > 0) ...[
                        const SizedBox(height: 12),
                        UnlockProgress(adPoints: user.adPoints),
                      ],
                      if (user.unlockedBonus > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: UiColors.mint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '₹${user.unlockedBonus} bonus unlocked. It will be added to your withdrawal total once you\'re eligible to withdraw.',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF2F4A41),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      Material(
                        color: UiColors.sand,
                        borderRadius: BorderRadius.circular(40),
                        elevation: 5,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: () => context.go('/withdraw'),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text('Withdraw Funds',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: UiColors.onSand,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      _title('Withdrawal history'),
                      const SizedBox(height: 12),

                      StreamBuilder<List<WithdrawalRequest>>(
                        stream: firestoreService.streamWithdrawals(uid),
                        builder: (context, wSnapshot) {
                          final withdrawals = wSnapshot.data ?? [];

                          if (withdrawals.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('No withdrawals yet.',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: UiColors.muted,
                                      fontWeight: FontWeight.w500)),
                            );
                          }

                          return Column(
                            children: withdrawals.map((w) {
                              Color statusColor;
                              String statusLabel;
                              switch (w.status) {
                                case WithdrawalStatus.paid:
                                  statusColor = const Color(0xFF2E9E6B);
                                  statusLabel = 'Paid';
                                  break;
                                case WithdrawalStatus.approved:
                                  statusColor = const Color(0xFF3B7DD8);
                                  statusLabel = 'Approved';
                                  break;
                                case WithdrawalStatus.rejected:
                                  statusColor = UiColors.danger;
                                  statusLabel = 'Rejected';
                                  break;
                                case WithdrawalStatus.pending:
                                  statusColor = const Color(0xFFD99A00);
                                  statusLabel = 'Pending';
                                  break;
                              }
                              return _listCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '₹${w.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  color: UiColors.ink,
                                                  fontWeight:
                                                      FontWeight.w800)),
                                          const SizedBox(height: 2),
                                          Text(
                                            w.requestedAt != null
                                                ? DateFormat('MMM d, h:mm a')
                                                    .format(w.requestedAt!)
                                                : 'Just now',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: UiColors.muted,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                            alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(statusLabel,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      _title('Transaction history'),
                      const SizedBox(height: 12),

                      StreamBuilder<List<AppTransaction>>(
                        stream: firestoreService.streamRecentTransactions(uid),
                        builder: (context, txSnapshot) {
                          if (txSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }

                          final transactions = txSnapshot.data ?? [];

                          if (transactions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No transactions yet.\nWatch an ad to get started!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: UiColors.muted,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: transactions.map((tx) {
                              final isNegative = tx.amount < 0;
                              return _listCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isNegative
                                            ? UiColors.peach
                                            : UiColors.mint,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_iconForType(tx.type),
                                          color: UiColors.ink, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (tx.type ==
                                                        TransactionType
                                                            .taskCompleted &&
                                                    tx.taskTitle.isNotEmpty
                                                ? tx.taskTitle
                                                : _labelForType(tx.type)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 14.5,
                                                color: UiColors.ink,
                                                fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tx.timestamp != null
                                                ? DateFormat('MMM d, h:mm a')
                                                    .format(tx.timestamp!)
                                                : 'Just now',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: UiColors.muted,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isNegative ? '' : '+'}${tx.amount}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isNegative
                                              ? UiColors.danger
                                              : const Color(0xFF2E9E6B)),
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
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}