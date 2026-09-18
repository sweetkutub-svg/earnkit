import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ad_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _adService = AdService();
  bool _isAdLoading = false;
  static const int _dailyAdCap = 20;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    setState(() => _isAdLoading = true);
    _adService.loadRewardedAd(
      onLoaded: () {
        if (mounted) setState(() => _isAdLoading = false);
      },
      onFailed: (error) {
        if (mounted) setState(() => _isAdLoading = false);
        // ignore: avoid_print
        print('Ad failed to load: $error');
      },
    );
  }

  void _watchAd() {
    if (!_adService.isAdReady) return;
    _adService.showRewardedAd(
      onEarnedReward: (pointsCredited) {
        if (!mounted) return;
        AppDialog.showSuccess(
            context, 'You earned +$pointsCredited Earnkit Points!');
      },
      onCreditFailed: (error) {
        if (!mounted) return;
        AppDialog.showError(context, error);
      },
      onAdClosed: () {
        _loadAd(); // preload next ad
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<AppUser?>(
              stream: _firestoreService.streamUserData(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = snapshot.data;
                if (user == null) {
                  return const Center(child: Text('User data not found'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Wallet balance card
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
                            Text(
                              'Available Balance',
                              style: AppTextStyles.bodyText.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${user.walletBalance}',
                                  style: AppTextStyles.h1ScreenTitle
                                      .copyWith(color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Earnkit Points',
                                  style: AppTextStyles.bodyText.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    '₹${user.lockedBonus} Locked',
                                    style: AppTextStyles.caption
                                        .copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Watch Ad & Earn card — with live daily-cap tracking
                      StreamBuilder<List<AppTransaction>>(
                        stream: _firestoreService.streamTransactions(uid),
                        builder: (context, txSnapshot) {
                          final allTx = txSnapshot.data ?? [];
                          final now = DateTime.now();
                          final todayStart =
                              DateTime(now.year, now.month, now.day);
                          final adsWatchedToday = allTx
                              .where((tx) =>
                                  tx.type == TransactionType.adWatched &&
                                  tx.timestamp != null &&
                                  tx.timestamp!.isAfter(todayStart))
                              .length;
                          final capReached = adsWatchedToday >= _dailyAdCap;
                          final progress =
                              (adsWatchedToday / _dailyAdCap).clamp(0.0, 1.0);

                          return InkWell(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radius),
                            onTap: capReached ||
                                    _isAdLoading ||
                                    !_adService.isAdReady
                                ? null
                                : _watchAd,
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
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: capReached
                                              ? AppColors.gray100
                                              : AppColors.lightEmerald,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: capReached
                                              ? AppColors.gray400
                                              : AppColors.emerald,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Watch Ad & Earn',
                                                style:
                                                    AppTextStyles.h3CardTitle),
                                            Text(
                                              capReached
                                                  ? 'Daily limit reached'
                                                  : _isAdLoading
                                                      ? 'Loading ad...'
                                                      : _adService.isAdReady
                                                          ? 'Test ad ready'
                                                          : 'Ad not available',
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isAdLoading && !capReached)
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      else if (!capReached)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.amberLight,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text('TEST',
                                              style: TextStyle(
                                                  color: AppColors.gold,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Daily Ads Limit',
                                          style: AppTextStyles.caption),
                                      Text(
                                          '$adsWatchedToday / $_dailyAdCap Watched',
                                          style: AppTextStyles.caption),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: AppColors.gray200,
                                      valueColor: AlwaysStoppedAnimation(
                                        capReached
                                            ? AppColors.errorRed
                                            : AppColors.emerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text('Earn More Tasks',
                          style: AppTextStyles.h2SectionHeader),
                      const SizedBox(height: AppSpacing.sm),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text(
                          'Offerwall tasks will appear here once integrated (Phase 12).',
                          style: AppTextStyles.bodyText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.emerald,
        currentIndex: 0,
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