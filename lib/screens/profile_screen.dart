import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'codewithkutub@gmail.com',
      query: 'subject=Earnkit Support Request',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final user = authService.currentUser;
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<AppUser?>(
              stream: firestoreService.streamUserData(uid),
              builder: (context, snapshot) {
                final appUser = snapshot.data;

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
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.emerald,
                            child: Text(
                              (appUser?.name.isNotEmpty == true
                                      ? appUser!.name[0]
                                      : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(appUser?.name ?? 'User',
                              style: AppTextStyles.h2SectionHeader),
                          Text(appUser?.email ?? '',
                              style: AppTextStyles.caption),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: authService.isEmailVerified
                                  ? AppColors.lightEmerald
                                  : AppColors.amberLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              authService.isEmailVerified
                                  ? 'Email Verified'
                                  : 'Email Not Verified',
                              style: TextStyle(
                                color: authService.isEmailVerified
                                    ? AppColors.emerald
                                    : AppColors.gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.history,
                                color: AppColors.emerald),
                            title: const Text('Withdrawal History'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/wallet'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.people_outline,
                                color: AppColors.emerald),
                            title: const Text('Refer & Earn'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/referral'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined,
                                color: AppColors.emerald),
                            title: const Text('Notification Preferences'),
                            trailing: Switch(
                              value: appUser != null,
                              activeThumbColor: AppColors.emerald,
                              onChanged: (value) async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({'notificationsEnabled': value});
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.help_outline,
                                color: AppColors.emerald),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _contactSupport,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.description_outlined,
                                color: AppColors.emerald),
                            title: const Text('Terms & Privacy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/terms'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                        ),
                        onPressed: () async {
                          await authService.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        child: const Text('Logout Account'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text('App Version 1.0.0',
                          style: AppTextStyles.caption),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}