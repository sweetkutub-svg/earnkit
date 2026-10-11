import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/banner_ad_widget.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const _routes = ['/home', '/wallet', '/tasks', '/withdraw', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner sits above the nav bar with a gap so taps on the
        // nav buttons never land on the ad by accident.
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          alignment: Alignment.center,
          child: const BannerAdWidget(),
        ),
        BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.emerald,
          currentIndex: currentIndex,
          onTap: (i) {
            if (i != currentIndex) context.go(_routes[i]);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
            BottomNavigationBarItem(
                icon: Icon(Icons.currency_rupee), label: 'Withdraw'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ],
    );
  }
}