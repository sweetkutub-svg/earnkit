import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/ui_colors.dart';
import '../services/interstitial_service.dart';

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem(this.icon, this.label, this.path);
}

/// Floating pill navigation bar.
/// Index: 0 Home, 1 Wallet, 2 Tasks, 3 Withdraw, 4 Profile.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const _items = [
    _NavItem(Icons.home_rounded, 'Home', '/home'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Wallet', '/wallet'),
    _NavItem(Icons.task_alt_rounded, 'Tasks', '/earn-more'),
    _NavItem(Icons.payments_rounded, 'Withdraw', '/withdraw'),
    _NavItem(Icons.person_rounded, 'Profile', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: UiColors.sand,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (selected) return;
                  context.go(item.path);
                  InterstitialService().maybeShowOnSwitch();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 16 : 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? UiColors.mint : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: selected ? UiColors.ink : UiColors.onSandSoft,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(item.label,
                            style: const TextStyle(
                                fontSize: 13,
                                color: UiColors.ink,
                                fontWeight: FontWeight.w800)),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}