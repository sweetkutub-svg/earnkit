import '../widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ad_service.dart';
import '../services/device_service.dart';
import '../services/fraud_report_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';
import '../widgets/app_dialog.dart';
import '../widgets/bonus_unlocked_dialog.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
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
  final _deviceService = DeviceService();
  bool _isAdLoading = false;
  bool _isDeviceFlagged = false;
  static const int _dailyAdCap = 20;

  @override
  void initState() {
    super.initState();
    _checkDeviceAndLoadAd();
  }

  Future<void> _checkDeviceAndLoadAd() async {
    final flagged = await _deviceService.isDeviceFlagged();
    if (mounted) setState(() => _isDeviceFlagged = flagged);
    if (flagged) {
      FraudReportService.reportOncePerSession(
        'EMULATOR_OR_ROOT',
        deviceId: await _deviceService.getDeviceId(),
      );
    }
    if (!flagged) {
      _loadAd();
    }
    await NotificationService().init();
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'payment') {
        NotificationService.showPayment(message);
        return;
      }
      if (!mounted) return;
      final title = message.notification?.title ?? 'Earnkit';
      final body = message.notification?.body ?? '';
      AppDialog.show(context, title: title, message: body);
    });
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
      onEarnedReward: (pointsCredited, bonusUnlocked, bonusAmount) {
        if (!mounted) return;
        if (bonusUnlocked) {
          BonusUnlockedDialog.show(context, bonusAmount);
        } else {
          AppDialog.showSuccess(
              context, 'You earned +$pointsCredited Earnkit Points!');
        }
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

  Future<void> _openTask(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    var link = url.trim();

    if (link.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This task has no link yet.')),
      );
      return;
    }

    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid link.')),
      );
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  Widget _buildTaskCard(AppTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTextStyles.h3CardTitle),
                if (task.description.isNotEmpty)
                  Text(task.description, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${task.rewardPoints}',
                  style: AppTextStyles.h3CardTitle
                      .copyWith(color: AppColors.emerald)),
              ElevatedButton(
                onPressed: () => context.push('/task', extra: task),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: () => context.go('/tasks'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          children: [
            const Icon(Icons.assignment_outlined,
                color: AppColors.gray400, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No tasks available yet — check back soon!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText,
            ),
          ],
        ),
      ),
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
                      const BannerAdWidget(),

                      if (_isDeviceFlagged)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.block,
                                  color: AppColors.gray600),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Ad-earning is disabled on this device for security reasons.',
                                  style: AppTextStyles.bodyText,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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
                            final progress = (adsWatchedToday / _dailyAdCap)
                                .clamp(0.0, 1.0);

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
                                  border:
                                      Border.all(color: AppColors.gray200),
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
                                                  style: AppTextStyles
                                                      .h3CardTitle),
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

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius),
                        onTap: () => context.push('/referral'),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.lightEmerald,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  color: AppColors.emerald),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Refer & Earn',
                                        style: AppTextStyles.h3CardTitle),
                                    Text('Earn ₹5 per friend who joins',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.emerald),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Earn More Tasks',
                              style: AppTextStyles.h2SectionHeader),
                          TextButton(
                            onPressed: () => context.go('/tasks'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      

                      // Live tasks from Firestore (first 3)
                      StreamBuilder<List<AppTask>>(
                        stream: _firestoreService.streamActiveTasks(),
                        builder: (context, taskSnapshot) {
                          if (taskSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !taskSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }

                          final tasks =
                              (taskSnapshot.data ?? []).take(3).toList();

                          if (tasks.isEmpty) {
                            return _buildEmptyTasks();
                          }
                          

                          return Column(
                            children: tasks.map(_buildTaskCard).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0), 
      
    );
  }
}