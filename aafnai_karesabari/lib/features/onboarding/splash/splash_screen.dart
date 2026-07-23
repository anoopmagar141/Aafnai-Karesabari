import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../routing/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go(AppRoutes.languageSelect);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.eco_rounded, color: AppColors.primary, size: 96),
              SizedBox(height: 20),
              Text('Hamro Karesabari', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
              SizedBox(height: 8),
              Text('मेरो करेसाबारी\nFrom local farms to your home', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            ]),
          ),
        ),
      );
}
