import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/primary_button.dart';
import '../onboarding_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final AuthService _auth = FirebaseAuthService();
  final UserRepository _users = FirestoreUserRepository();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Set up your profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 24),
              TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  validator: _required),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                enabled: !_saving,
                decoration: const InputDecoration(
                    labelText: 'Delivery address'),
                validator: _required,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                  label: _saving ? 'Saving...' : 'Continue',
                  onPressed: _saving ? null : _saveProfile),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return _showError(
          'Your sign-in session has expired. Please sign in again.');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final baseUser = AppUser(
        id: firebaseUser.uid,
        name: _nameController.text.trim(),
        phone: firebaseUser.phoneNumber ?? '',
        language: onboardingController.languageCode == 'ne'
            ? AppLanguage.ne
            : AppLanguage.en,
        email: firebaseUser.email ?? '',
        location: _locationController.text.trim(),
        createdAt: DateTime.now(),
        profileCompleted: true,
        isSeller: false,
        sellerVerified: false,
      );

      await _users.save(baseUser);
      onboardingController.completeProfile();
      if (!mounted) return;
      context.go(AppRoutes.consumerHome);
    } catch (_) {
      _showError(
          'Could not save your profile. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _saving = false;
      });
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}
