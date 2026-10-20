import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/ui_colors.dart';
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
                style: TextStyle(color: UiColors.danger)),
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
                  style: TextStyle(color: UiColors.danger)),
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

  Widget _iconBubble(IconData icon, Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: UiColors.ink),
      );

  Widget _group(String title, List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, indent: 66, endIndent: 16));
      }
      children.add(tiles[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: UiColors.muted,
                  fontWeight: FontWeight.w800)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: UiShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Material(
              color: Colors.white,
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, Color color, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBubble(icon, color),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15, color: UiColors.ink, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right, color: UiColors.muted),
      onTap: onTap,
    );
  }

  void _showLegalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    _iconBubble(Icons.privacy_tip_outlined, UiColors.mint),
                title: const Text('Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w700)),
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
                leading:
                    _iconBubble(Icons.description_outlined, UiColors.lilac),
                title: const Text('Terms of Service',
                    style: TextStyle(fontWeight: FontWeight.w700)),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: _iconBubble(Icons.notifications_outlined, UiColors.peach),
          title: const Text('Notifications',
              style: TextStyle(
                  fontSize: 15,
                  color: UiColors.ink,
                  fontWeight: FontWeight.w700)),
          subtitle: Text(enabled ? 'On' : 'Off',
              style: const TextStyle(fontSize: 12, color: UiColors.muted)),
          trailing: Switch(
            value: enabled,
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

  /// Big slate hero card: avatar on the left, name/email/status on the right.
  Widget _headerCard(AppUser? appUser, AuthService authService) {
    final name = (appUser?.name ?? '').trim();
    final verified = authService.isEmailVerified;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: UiColors.sand,
        borderRadius: BorderRadius.circular(32),
        boxShadow: UiShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: UiColors.mint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: const TextStyle(
                  color: UiColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Earnkit User' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(appUser?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: UiColors.onSandSoft,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: verified ? UiColors.mint : UiColors.peach,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verified ? Icons.verified : Icons.error_outline,
                        size: 14,
                        color: UiColors.ink,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        verified ? 'Email Verified' : 'Email Not Verified',
                        style: const TextStyle(
                          color: UiColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Big pastel shortcut tile (two sit side by side).
  Widget _quickTile(
      IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: UiShadows.card,
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: UiColors.ink),
                ),
                const SizedBox(height: 18),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12,
                        color: UiColors.ink.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                builder: (context, snapshot) {
                  final appUser = snapshot.data;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    children: [
                      const Text('Profile',
                          style: TextStyle(
                              fontSize: 30,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _headerCard(appUser, authService),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _quickTile(
                                  Icons.people_outline,
                                  UiColors.mint,
                                  'Refer & Earn',
                                  'Invite friends',
                                  () => context.push('/referral')),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _quickTile(
                                  Icons.history,
                                  UiColors.lilac,
                                  'History',
                                  'Withdrawals',
                                  () => context.push('/wallet')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _group('Preferences', [
                        _notificationTile(uid),
                      ]),
                      const SizedBox(height: 20),
                      _group('Support', [
                        _tile(Icons.help_outline, UiColors.peach,
                            'Help & Support', () => _contactSupport(context)),
                        _tile(Icons.description_outlined, UiColors.lilac,
                            'Terms & Privacy', () => _showLegalSheet(context)),
                        _tile(
                            Icons.delete_outline,
                            UiColors.danger.withValues(alpha: 0.2),
                            'Delete Account',
                            () => _confirmDelete(context, authService)),
                      ]),
                      const SizedBox(height: 26),
                      Material(
                        color: UiColors.danger,
                        borderRadius: BorderRadius.circular(40),
                        elevation: 5,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: () => _confirmLogout(context, authService),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Logout Account',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text('App Version 1.0.0',
                            style: TextStyle(
                                fontSize: 12,
                                color: UiColors.muted,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  );
                },
              ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}