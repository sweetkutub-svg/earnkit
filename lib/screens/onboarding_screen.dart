import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Earn by Watching Ads',
      description:
          'Watch premium video ads from world-class brands and earn rewards directly in your wallet.',
      icon: Icons.play_circle_outline,
    ),
    _OnboardingPageData(
      title: 'Invite & Earn Together',
      description:
          'Share the flow. Get up to ₹100 for every friend who signs up and starts earning. No limits.',
      icon: Icons.groups_outlined,
    ),
    _OnboardingPageData(
      title: 'Instant UPI Withdrawal',
      description:
          'Transfer your earned balance directly to any bank account via UPI. Instant, secure, and hassle-free.',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  void _goToLogin() {
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToLogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return PopScope(
      // Agar pehle slide pe ho toh app ko normally back/exit hone do (canPop: true).
      // Agar 2nd/3rd slide pe ho toh back button pehla slide pe le jaye, app exit na ho.
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousPage();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Skip button (hidden on last page)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: isLastPage
                      ? const SizedBox(height: 40)
                      : TextButton(
                          onPressed: _goToLogin,
                          child: Text(
                            'Skip',
                            style: AppTextStyles.bodyText
                                .copyWith(color: AppColors.gray600),
                          ),
                        ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              page.icon,
                              size: 90,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h1ScreenTitle,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyText,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.emerald
                          : AppColors.gray200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: isLastPage
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _goToLogin,
                          child: const Text('Get Started'),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _goToLogin,
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              child: const Text('Next'),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}