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
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

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

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Refer & Earn'),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<AppUser?>(
              stream: _firestoreService.streamUserData(uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = userSnapshot.data;
                if (user == null) {
                  return const Center(child: Text('User data not found'));
                }

                if (user.referralCode.isEmpty) {
                  _ensureReferralCode(user, uid);
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Container(
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
                          Text('Your Referral Code',
                              style: AppTextStyles.h3CardTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Share this code — earn ₹5 when your friend completes their first activity.',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.gray400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(user.referralCode,
                                    style: AppTextStyles.h2SectionHeader),
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      color: AppColors.emerald),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: user.referralCode));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Referral code copied!')));
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final message =
                                        '🎉 *Join Earnkit* — watch ads, complete tasks, and earn real rewards!\n\n'
                                        'Use my referral code: "${user.referralCode}"\n\n'
                                        'Sign up now and we both earn 🚀';
                                    Clipboard.setData(
                                        ClipboardData(text: message));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Referral message copied!')));
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final message =
                                        '🎉 *Join Earnkit* — watch ads, complete tasks, and earn real rewards!\n\n'
                                        'Use my referral code: "${user.referralCode}"\n\n'
                                        'Sign up now and we both earn 🚀';
                                    SharePlus.instance.share(
                                        ShareParams(text: message));
                                  },
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Share'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    StreamBuilder<List<ReferralRecord>>(
                      stream:
                          _firestoreService.streamReferralsByReferrer(uid),
                      builder: (context, refSnapshot) {
                        final referrals = refSnapshot.data ?? [];
                        final completedCount =
                            referrals.where((r) => r.completed).length;

                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radius),
                                  border:
                                      Border.all(color: AppColors.gray200),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Friends Referred',
                                        style: AppTextStyles.caption),
                                    const SizedBox(height: 6),
                                    Text('${referrals.length}',
                                        style: AppTextStyles.h1ScreenTitle),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radius),
                                  border:
                                      Border.all(color: AppColors.gray200),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Earned',
                                        style: AppTextStyles.caption),
                                    const SizedBox(height: 6),
                                    Text('₹${completedCount * 5}',
                                        style: AppTextStyles.h1ScreenTitle),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Referred Friends',
                        style: AppTextStyles.h2SectionHeader),
                    const SizedBox(height: AppSpacing.md),
                    StreamBuilder<List<ReferralRecord>>(
                      stream:
                          _firestoreService.streamReferralsByReferrer(uid),
                      builder: (context, refSnapshot) {
                        final referrals = refSnapshot.data ?? [];

                        if (referrals.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Center(
                              child: Text(
                                'No referrals yet.\nShare your code to start earning!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyText,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: referrals.map((ref) {
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
                                  CircleAvatar(
                                    backgroundColor:
                                        AppColors.lightEmerald,
                                    child: Icon(Icons.person_outline,
                                        color: AppColors.emerald),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Friend',
                                            style:
                                                AppTextStyles.h3CardTitle),
                                        Text(
                                          ref.createdAt != null
                                              ? 'Joined ${ref.createdAt!.day}/${ref.createdAt!.month}/${ref.createdAt!.year}'
                                              : 'Recently joined',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ref.completed
                                          ? AppColors.lightEmerald
                                          : AppColors.gray100,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      ref.completed ? 'Active' : 'Pending',
                                      style: TextStyle(
                                        color: ref.completed
                                            ? AppColors.emerald
                                            : AppColors.gray600,
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
                  ],
                );
              },
            ),
    );
  }
}