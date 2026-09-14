import 'package:flutter/material.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EarnkitApp());
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