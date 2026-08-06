import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/services/secure_token_store.dart';
import '../../../features/onboarding/onboarding_controller.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = FirebaseAuthService();
  final SecureTokenStore _tokenStore = SecureTokenStore();
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('Change language during a future update')),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () => context.go(AppRoutes.notifications),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(_signingOut ? 'Signing out...' : 'Log out',
                  style: const TextStyle(color: Colors.red)),
              enabled: !_signingOut,
              onTap: _confirmLogout,
            ),
          ],
        ),
      );

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'Log out?',
        message: 'You will need to sign in again to access your account.',
        destructive: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true) return;
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      await _tokenStore.clearSessionToken();
      onboardingController.reset();
      // Router automatically redirects based on authStateChanges
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }
}
