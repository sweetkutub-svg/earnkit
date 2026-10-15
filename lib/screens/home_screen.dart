import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../widgets/app_bottom_nav.dart';
import '../widgets/bonus_unlocked_dialog.dart';
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
  final _deviceService = DeviceService();
  bool _isAdLoading = false;
  bool _isDeviceFlagged = false;
  DateTime? _optimisticLastAd;
  Stream<AppUser?>? _userStream;
  Stream<List<AppTransaction>>? _txStream;
  Stream<List<AppTask>>? _taskStream;
  int _dailyAdCap = 20; // defaults, overridden by app_config/reward_config
  int _adGapSeconds = 10;
  int _referralBonus = 5;
  int _referralPoints = 110;

  Future<void> _loadRewardConfig() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('reward_config')
          .get();
      final d = snap.data();
      if (d == null || !mounted) return;
      final cap = (d['dailyAdCap'] as num?)?.toInt();
      final gap = (d['adGapSeconds'] as num?)?.toInt();
      final refBonus = (d['referralBonusAmount'] as num?)?.toInt();
      final refPoints = (d['referralUnlockPoints'] as num?)?.toInt();
      setState(() {
        if (cap != null && cap > 0) _dailyAdCap = cap;
        if (gap != null && gap >= 5) _adGapSeconds = gap;
        if (refBonus != null && refBonus > 0) _referralBonus = refBonus;
        if (refPoints != null && refPoints > 0) _referralPoints = refPoints;
      });
    } catch (_) {
      // keep defaults
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRewardConfig();
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
        setState(() => _optimisticLastAd = DateTime.now());
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
boxShadow: AppShadows.soft,
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
                onPressed: () => _openTask(task.url),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurveysCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: () => context.push('/surveys'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.gray200),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightEmerald,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.poll_outlined, color: AppColors.emerald),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Surveys', style: AppTextStyles.h3CardTitle),
                  Text('Complete surveys and earn bigger rewards',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.emerald),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: () => context.push('/earn-more'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.gray200),
boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            const Icon(Icons.assignment_outlined,
                color: AppColors.gray400, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No tasks available yet. Check back soon!',
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
              stream: _userStream ??= _firestoreService.streamUserData(uid),
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

                      _buildSurveysCard(),
                      const SizedBox(height: AppSpacing.lg),

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
                          stream: _txStream ??= _firestoreService.streamTodayAds(uid),
                          builder: (context, txSnapshot) {
                            final allTx = txSnapshot.data ?? [];
                            final now = DateTime.now();
                            final todayStart =
                                DateTime(now.year, now.month, now.day);

                            int adsWatchedToday = 0;
                            DateTime? lastAd;
                            for (final tx in allTx) {
                              if (tx.type != TransactionType.adWatched ||
                                  tx.timestamp == null) {
                                continue;
                              }
                              final t = tx.timestamp!;
                              if (t.isAfter(todayStart)) adsWatchedToday++;
                              if (lastAd == null || t.isAfter(lastAd)) {
                                lastAd = t;
                              }
                            }
                            final opt = _optimisticLastAd;
                            if (opt != null &&
                                (lastAd == null || opt.isAfter(lastAd))) {
                              lastAd = opt;
                            }

                            return _WatchAdCard(
                              watchedToday: adsWatchedToday,
                              dailyCap: _dailyAdCap,
                              gapSeconds: _adGapSeconds,
                              lastAdTime: lastAd,
                              isLoading: _isAdLoading,
                              isReady: _adService.isAdReady,
                              onWatch: _watchAd,
                              onRetry: _loadAd,
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
                                    Text('Earn ₹$_referralBonus per friend who reaches $_referralPoints points',
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
                            onPressed: () => context.push('/earn-more'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Live tasks from Firestore (first 3)
                      StreamBuilder<List<AppTask>>(
                        stream: _taskStream ??= _firestoreService.streamActiveTasks(),
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

/// The "Watch Ad & Earn" card. It owns its own 1-second timer, so only this
/// card rebuilds while the cooldown counts down, not the whole Home page.
class _WatchAdCard extends StatefulWidget {
  final int watchedToday;
  final int dailyCap;
  final int gapSeconds;
  final DateTime? lastAdTime;
  final bool isLoading;
  final bool isReady;
  final VoidCallback onWatch;
  final VoidCallback onRetry;

  const _WatchAdCard({
    required this.watchedToday,
    required this.dailyCap,
    required this.gapSeconds,
    required this.lastAdTime,
    required this.isLoading,
    required this.isReady,
    required this.onWatch,
    required this.onRetry,
  });

  @override
  State<_WatchAdCard> createState() => _WatchAdCardState();
}

class _WatchAdCardState extends State<_WatchAdCard> {
  Timer? _timer;
  int _shown = 0;

  int _left() {
    final last = widget.lastAdTime;
    if (last == null) return 0;
    final left =
        widget.gapSeconds - DateTime.now().difference(last).inSeconds;
    return left > 0 ? left : 0;
  }

  @override
  void initState() {
    super.initState();
    _shown = _left();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final l = _left();
      if (l != _shown && mounted) setState(() => _shown = l);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capReached = widget.watchedToday >= widget.dailyCap;
    final left = _left();
    final progress =
        (widget.watchedToday / widget.dailyCap).clamp(0.0, 1.0);

    String status;
    String label;
    IconData icon;
    VoidCallback? action;

    if (capReached) {
      status = 'Daily limit reached';
      label = 'Daily limit reached';
      icon = Icons.block;
      action = null;
    } else if (left > 0) {
      status = 'Next ad in ${left}s';
      label = 'Next ad in ${left}s';
      icon = Icons.timer_outlined;
      action = null;
    } else if (widget.isLoading) {
      status = 'Loading ad...';
      label = 'Loading ad...';
      icon = Icons.hourglass_empty;
      action = null;
    } else if (widget.isReady) {
      status = 'Ad ready';
      label = 'Watch Ad & Earn';
      icon = Icons.play_circle_outline;
      action = widget.onWatch;
    } else {
      status = 'Ad not available';
      label = 'Retry loading ad';
      icon = Icons.refresh;
      action = widget.onRetry;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.gray200),
boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      capReached ? AppColors.gray100 : AppColors.lightEmerald,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  color: capReached ? AppColors.gray400 : AppColors.emerald,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watch Ad & Earn', style: AppTextStyles.h3CardTitle),
                    Text(status, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Ads Limit', style: AppTextStyles.caption),
              Text('${widget.watchedToday} / ${widget.dailyCap} Watched',
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
                capReached ? AppColors.errorRed : AppColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: action,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shadowColor: AppColors.emerald.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}