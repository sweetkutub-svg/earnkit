import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/referral_screen.dart';
import 'screens/post_signup_referral_screen.dart';
import 'screens/earn_more_screen.dart';
import 'screens/task_detail_screen.dart';
import 'models/task_model.dart';
import 'screens/home_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/post-signup',
      builder: (context, state) => const PostSignupReferralScreen(),
    ),
    GoRoute(
      path: '/earn-more',
      builder: (context, state) => const EarnMoreScreen(),
    ),
    GoRoute(
      path: '/task',
      builder: (context, state) =>
          TaskDetailScreen(task: state.extra as AppTask),
    ),

    GoRoute(path: '/tasks', builder: (context, state) => const EarnMoreScreen()), GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
    GoRoute(
      path: '/withdraw',
      builder: (context, state) => const WithdrawScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
