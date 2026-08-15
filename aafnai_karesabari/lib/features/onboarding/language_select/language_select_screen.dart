import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../onboarding_controller.dart';

/// First-run (or "Get started") language picker — English or Nepali —
/// persisted via [OnboardingController].
class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your language')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _LanguageChoice(
                label: 'नेपाली',
                onPressed: () {
                  onboardingController.selectLanguage('ne');
                  context.go(AppRoutes.register);
                },
              ),
              const SizedBox(height: 16),
              _LanguageChoice(
                label: 'English',
                onPressed: () {
                  onboardingController.selectLanguage('en');
                  context.go(AppRoutes.register);
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 96,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      );
}
