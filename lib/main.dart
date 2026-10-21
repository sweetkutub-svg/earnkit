import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/interstitial_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const EarnkitApp());
  // Initialize the Mobile Ads SDK in the background so app startup isn't blocked.
  MobileAds.instance.initialize().then((_) => InterstitialService().preload());
}

class EarnkitApp extends StatelessWidget {
  const EarnkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Earnkit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
