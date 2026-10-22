import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ad_service.dart';
import '../services/device_service.dart';
import '../services/fraud_report_service.dart';
import '../services/location_report_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/bonus_unlocked_dialog.dart';
import '../theme/ui_colors.dart';
import '../widgets/skeleton.dart';

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
  static const int _dailyAdCap = 20;
  static const int _adGapSeconds = 10; // keep in sync with backend

  @override
  void initState() {
    super.initState();
    LocationReportService.reportOncePerDay();
    AdService().preloadGateAd();
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

  // ---------- Header ----------

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _header() {
    final u = _authService.currentUser;
    var name = (u?.displayName ?? '').trim();
    if (name.isEmpty) {
      final email = (u?.email ?? '').trim();
      name = email.contains('@') ? email.split('@').first : 'there';
    }
    final first = name.split(' ').first;
    final initial = first.isEmpty ? 'E' : first[0].toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                  style: const TextStyle(
                      fontSize: 14,
                      color: UiColors.muted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: UiColors.sand,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(initial,
              style: const TextStyle(
                  fontSize: 18,
                  color: UiColors.onSand,
                  fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  // ---------- Balance (sand hero card) ----------

  Widget _balanceCard(AppUser user) {
    return Container(
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
          Row(
            children: [
              const Expanded(
                child: Text('Available balance',
                    style: TextStyle(
                        fontSize: 14,
                        color: UiColors.onSandSoft,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 14, color: UiColors.onSand),
                    const SizedBox(width: 6),
                    Text('₹${user.lockedBonus} locked',
                        style: const TextStyle(
                            fontSize: 12,
                            color: UiColors.onSand,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${user.walletBalance}',
                  style: const TextStyle(
                      fontSize: 52,
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
    );
  }

  // ---------- Quick actions ----------

  Widget _tile({
    required Color color,
    required IconData icon,
    required String title,
    required String caption,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: UiColors.ink),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF55555A),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        _tile(
          color: UiColors.lilac,
          icon: Icons.task_alt_outlined,
          title: 'Tasks',
          caption: 'Earn more',
          onTap: () => context.push('/earn-more'),
        ),
        const SizedBox(width: 10),
        _tile(
          color: UiColors.peach,
          icon: Icons.poll_outlined,
          title: 'Surveys',
          caption: 'Quick rewards',
          onTap: () => context.push('/surveys'),
        ),
        const SizedBox(width: 10),
        _tile(
          color: UiColors.mint,
          icon: Icons.people_outline,
          title: 'Refer',
          caption: 'Invite friends',
          onTap: () => context.push('/referral'),
        ),
      ],
    );
  }

  // ---------- Tasks ----------

  Widget _sectionHeader(String title, {String? action, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  color: UiColors.ink,
                  fontWeight: FontWeight.w800)),
        ),
        if (action != null)
          Material(
            color: UiColors.sand,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(action,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: UiColors.onSand,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard(AppTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: UiShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800)),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: UiColors.muted,
                          fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UiColors.lilac,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${task.rewardPoints} pts',
                      style: const TextStyle(
                          fontSize: 12,
                          color: UiColors.ink,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: UiColors.sand,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _openTask(task.url),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                child: Text('Start',
                    style: TextStyle(
                        fontSize: 13.5,
                        color: UiColors.onSand,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/earn-more'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: UiShadows.card,
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, color: UiColors.muted, size: 32),
            SizedBox(height: 8),
            Text('No tasks available yet. Check back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: UiColors.muted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _flaggedCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: UiShadows.card,
      ),
      child: const Row(
        children: [
          Icon(Icons.block, color: UiColors.danger),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ad-earning is disabled on this device for security reasons.',
              style: TextStyle(
                  fontSize: 14,
                  color: UiColors.ink,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        bottom: false,
        child: uid == null
            ? const Center(child: Text('Not logged in'))
            : StreamBuilder<AppUser?>(
                stream: _userStream ??= _firestoreService.streamUserData(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const HomeSkeleton();
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
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: [
                        _header(),
                        const SizedBox(height: 18),
                        _balanceCard(user),
                        const SizedBox(height: 14),

                        if (_isDeviceFlagged)
                          _flaggedCard()
                        else
                          StreamBuilder<List<AppTransaction>>(
                            stream: _txStream ??=
                                _firestoreService.streamTransactions(uid),
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
                        const SizedBox(height: 14),

                        _quickActions(),
                        const SizedBox(height: 22),

                        _sectionHeader('Earn more tasks',
                            action: 'View all',
                            onTap: () => context.push('/earn-more')),
                        const SizedBox(height: 12),

                        // Live tasks from Firestore (first 3)
                        StreamBuilder<List<AppTask>>(
                          stream:
                              _taskStream ??= _firestoreService.streamActiveTasks(),
                          builder: (context, taskSnapshot) {
                            if (taskSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !taskSnapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                    child: Shimmer(child: SkeletonBox(height: 96, radius: 24))),
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

class _WatchAdCardState extends State<_WatchAdCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _shown = 0;

  late final AnimationController _anim;
  late final Animation<double> _bounce;
  late final Animation<double> _shine;

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

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Ping-pong style: big hop, smaller hop, tiny hop, then a pause.
    TweenSequenceItem<double> hop(double h, double w) => TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: -h)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: w,
        );
    TweenSequenceItem<double> drop(double h, double w) => TweenSequenceItem(
          tween: Tween<double>(begin: -h, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: w,
        );
    _bounce = TweenSequence<double>([
      hop(14, 10),
      drop(14, 10),
      hop(7, 7),
      drop(7, 7),
      hop(3, 5),
      drop(3, 5),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 56),
    ]).animate(_anim);

    // A light streak that sweeps across the button after the bounce.
    _shine = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.35, 0.8, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  Widget _shineOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: LayoutBuilder(
            builder: (context, cs) {
              final w = cs.maxWidth;
              return AnimatedBuilder(
                animation: _shine,
                builder: (context, _) {
                  final x = -w * 0.35 + (w * 1.35) * _shine.value;
                  return Transform.translate(
                    offset: Offset(x, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform(
                        transform: Matrix4.skewX(-0.35),
                        child: Container(
                          width: w * 0.28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capReached = widget.watchedToday >= widget.dailyCap;
    final left = _left();
    final progress =
        (widget.watchedToday / widget.dailyCap).clamp(0.0, 1.0).toDouble();

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
      icon = Icons.play_arrow_rounded;
      action = widget.onWatch;
    } else {
      status = 'Ad not available';
      label = 'Retry loading ad';
      icon = Icons.refresh;
      action = widget.onRetry;
    }

    final enabled = action != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: UiColors.mint,
        borderRadius: BorderRadius.circular(28),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Watch Ad & Earn',
                        style: TextStyle(
                            fontSize: 21,
                            height: 1.15,
                            color: UiColors.ink,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(status,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3F5A52),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          '${widget.watchedToday} of ${widget.dailyCap} today',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 9,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      color: capReached ? UiColors.danger : UiColors.sand,
                    ),
                    Center(
                      child: Text('${widget.watchedToday}',
                          style: const TextStyle(
                              fontSize: 22,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, enabled ? _bounce.value : 0),
              child: child,
            ),
            child: Material(
              color: enabled ? UiColors.sand : UiColors.disabled,
              borderRadius: BorderRadius.circular(40),
              elevation: enabled ? 5 : 0,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: action,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(7),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: enabled ? UiColors.mint : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: UiColors.ink, size: 26),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: enabled
                                          ? UiColors.onSand
                                          : const Color(0xFF6A6A6F),
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                          Icon(Icons.keyboard_double_arrow_right_rounded,
                              color: enabled
                                  ? UiColors.onSandSoft
                                  : Colors.black26),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    if (enabled) _shineOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}