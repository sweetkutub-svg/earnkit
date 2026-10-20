import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/referral_model.dart';
import '../theme/ui_colors.dart';
import '../widgets/skeleton.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Defaults, overridden by app_config/reward_config
  int _bonus = 5;
  int _points = 110;

  Stream<AppUser?>? _userStream;
  Stream<List<ReferralRecord>>? _refStream;

  static const _green = Color(0xFF2E9E6B);

  @override
  void initState() {
    super.initState();
    _loadRewardConfig();
  }

  Future<void> _loadRewardConfig() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('reward_config')
          .get();
      final d = snap.data();
      if (d == null || !mounted) return;
      final bonus = (d['referralBonusAmount'] as num?)?.toInt();
      final points = (d['referralUnlockPoints'] as num?)?.toInt();
      setState(() {
        if (bonus != null && bonus > 0) _bonus = bonus;
        if (points != null && points > 0) _points = points;
      });
    } catch (_) {
      // keep defaults
    }
  }

  String _inviteMessage(String code) {
    return '🎉 *Join Earnkit* — watch ads, complete tasks, and earn real rewards!\n\n'
        'Use my referral code: "$code"\n\n'
        'Join here: https://earnkit-backend.vercel.app/ref/$code\n\n'
        'Sign up now and we both earn 🚀';
  }

  Future<void> _ensureReferralCode(AppUser user, String uid) async {
    if (user.referralCode.isNotEmpty) return;

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final db = FirebaseFirestore.instance;

    for (int attempt = 0; attempt < 5; attempt++) {
      final code =
          List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
      final codeRef = db.collection('referral_codes').doc(code);
      final codeSnap = await codeRef.get();
      if (!codeSnap.exists) {
        await codeRef.set({'uid': uid});
        await db.collection('users').doc(uid).update({'referralCode': code});
        return;
      }
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // ---------- UI pieces ----------

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: UiShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _back,
              child: const Icon(Icons.arrow_back_rounded,
                  color: UiColors.ink, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Refer & Earn',
            style: TextStyle(
                fontSize: 26,
                color: UiColors.ink,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _heroCard(AppUser user) {
    final code = user.referralCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: UiColors.sand,
        borderRadius: BorderRadius.circular(32),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Earn per friend',
                        style: TextStyle(
                            fontSize: 14,
                            color: UiColors.onSandSoft,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('\u20B9$_bonus',
                        style: const TextStyle(
                            fontSize: 52,
                            height: 1,
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: UiColors.mint, shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard,
                    size: 30, color: UiColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You get \u20B9$_bonus when your friend earns $_points points.',
            style: const TextStyle(
                fontSize: 13,
                color: UiColors.onSandSoft,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          // Code box
          Container(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR CODE',
                          style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              color: UiColors.muted,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(code,
                          style: const TextStyle(
                              fontSize: 26,
                              letterSpacing: 3,
                              color: UiColors.sand,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Material(
                  color: UiColors.bg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral code copied!')));
                    },
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.copy_rounded,
                          size: 20, color: UiColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _inviteMessage(code)));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Referral message copied!')));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy, size: 17, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Copy invite',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: UiColors.mint,
                  borderRadius: BorderRadius.circular(30),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      SharePlus.instance
                          .share(ShareParams(text: _inviteMessage(code)));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, size: 17, color: UiColors.ink),
                          SizedBox(width: 6),
                          Text('Share',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: UiColors.ink,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    Widget step(int n, Color c, String title, String sub, {bool last = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$n',
                  style: const TextStyle(
                      fontSize: 15,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5,
                          color: UiColors.ink,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: UiColors.muted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works',
              style: TextStyle(
                  fontSize: 17,
                  color: UiColors.ink,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          step(1, UiColors.mint, 'Share your code',
              'Send your link or code to friends.'),
          step(2, UiColors.lilac, 'Friend joins',
              'They sign up using your referral.'),
          step(3, UiColors.peach, 'You earn \u20B9$_bonus',
              'When they reach $_points points.',
              last: true),
        ],
      ),
    );
  }

  Widget _statTile(Color color, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          boxShadow: UiShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: UiColors.ink),
            ),
            const SizedBox(height: 14),
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF55555A),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _friendCard(ReferralRecord ref) {
    final chip = ref.completed ? _green : UiColors.muted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: UiShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                color: UiColors.lilac, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline,
                color: UiColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Friend',
                    style: TextStyle(
                        fontSize: 14.5,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  ref.createdAt != null
                      ? 'Joined ${ref.createdAt!.day}/${ref.createdAt!.month}/${ref.createdAt!.year}${ref.completed ? '' : ' • needs $_points points'}'
                      : 'Recently joined',
                  style: const TextStyle(
                      fontSize: 12,
                      color: UiColors.muted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: chip.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ref.completed ? 'Active' : 'Pending',
              style: TextStyle(
                  color: chip, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 200, height: 44, radius: 22),
            SizedBox(height: 16),
            SkeletonBox(height: 250, radius: 32),
            SizedBox(height: 14),
            SkeletonBox(height: 190, radius: 28),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 110, radius: 26)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 110, radius: 26)),
              ],
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
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text('Not logged in'))
            : StreamBuilder<AppUser?>(
                stream: _userStream ??= _firestoreService.streamUserData(uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting &&
                      !userSnapshot.hasData) {
                    return _loading();
                  }
                  final user = userSnapshot.data;
                  if (user == null) {
                    return const Center(child: Text('User data not found'));
                  }

                  if (user.referralCode.isEmpty) {
                    _ensureReferralCode(user, uid);
                    return _loading();
                  }

                  final refStream = _refStream ??=
                      _firestoreService.streamReferralsByReferrer(uid);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _heroCard(user),
                      const SizedBox(height: 14),
                      _howItWorks(),
                      const SizedBox(height: 14),
                      StreamBuilder<List<ReferralRecord>>(
                        stream: refStream,
                        builder: (context, refSnapshot) {
                          final referrals = refSnapshot.data ?? [];
                          final completedCount =
                              referrals.where((r) => r.completed).length;

                          return Row(
                            children: [
                              _statTile(UiColors.lilac, Icons.people_outline,
                                  'Friends referred', '${referrals.length}'),
                              const SizedBox(width: 12),
                              _statTile(
                                  UiColors.mint,
                                  Icons.currency_rupee,
                                  'Total earned',
                                  '\u20B9${completedCount * _bonus}'),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      const Text('Referred friends',
                          style: TextStyle(
                              fontSize: 20,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      StreamBuilder<List<ReferralRecord>>(
                        stream: refStream,
                        builder: (context, refSnapshot) {
                          final referrals = refSnapshot.data ?? [];

                          if (referrals.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No referrals yet.\nShare your code to start earning!',
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
                            children: referrals.map(_friendCard).toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}