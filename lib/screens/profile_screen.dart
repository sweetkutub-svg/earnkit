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
import 'legal_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _supportEmail = 'codewithkutub@gmail.com';

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Earnkit Support Request',
    );
    bool opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email app found. Write to $_supportEmail'),
        ),
      );
    }
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthService authService) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use Earnkit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await authService.signOut();
    if (context.mounted) context.go('/login');
  }

  Future<void> _confirmDelete(
      BuildContext context, AuthService authService) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'This permanently deletes your account, points and bonus. This cannot be undone.'),
              const SizedBox(height: 12),
              const Text('Type DELETE to confirm.'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final error = await authService.deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loader
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go('/login');
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _group(String title, List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) children.add(const Divider(height: 1));
      children.add(tiles[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(title,
              style: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.gray200),
boxShadow: AppShadows.soft,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.emerald),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLegalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: AppColors.emerald),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LegalScreen(
                    title: 'Privacy Policy',
                    field: 'privacyPolicy',
                  ),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.emerald),
              title: const Text('Terms of Service'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LegalScreen(
                    title: 'Terms of Service',
                    field: 'termsOfService',
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final enabled = (data?['notificationsEnabled'] as bool?) ?? true;
        return ListTile(
          leading: const Icon(Icons.notifications_outlined,
              color: AppColors.emerald),
          title: const Text('Notifications'),
          subtitle: Text(enabled ? 'On' : 'Off', style: AppTextStyles.caption),
          trailing: Switch(
            value: enabled,
            activeThumbColor: AppColors.emerald,
            onChanged: snap.hasData
                ? (value) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'notificationsEnabled': value});
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not update. Try again.')),
                        );
                      }
                    }
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _headerCard(AppUser? appUser, AuthService authService) {
    final name = (appUser?.name ?? '').trim();
    final verified = authService.isEmailVerified;

    return Container(
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
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.emerald,
            child: Text(
              _initials(name),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name.isEmpty ? 'Earnkit User' : name,
              style: AppTextStyles.h2SectionHeader),
          const SizedBox(height: 2),
          Text(appUser?.email ?? '', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: verified ? AppColors.lightEmerald : AppColors.amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verified ? Icons.verified : Icons.error_outline,
                  size: 14,
                  color: verified ? AppColors.emerald : AppColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  verified ? 'Email Verified' : 'Email Not Verified',
                  style: TextStyle(
                    color: verified ? AppColors.emerald : AppColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final uid = authService.currentUser?.uid;

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
                    _headerCard(appUser, authService),
                    const SizedBox(height: AppSpacing.lg),
                    _group('Account', [
                      _tile(Icons.history, 'Withdrawal History',
                          () => context.push('/wallet')),
                      _tile(Icons.people_outline, 'Refer & Earn',
                          () => context.push('/referral')),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    _group('Preferences', [
                      _notificationTile(uid),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    _group('Support', [
                      _tile(Icons.help_outline, 'Help & Support',
                          () => _contactSupport(context)),
                      _tile(Icons.description_outlined, 'Terms & Privacy',
                          () => _showLegalSheet(context)),
                      _tile(Icons.delete_outline, 'Delete Account',
                          () => _confirmDelete(context, authService)),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                        ),
                        onPressed: () => _confirmLogout(context, authService),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout Account'),
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