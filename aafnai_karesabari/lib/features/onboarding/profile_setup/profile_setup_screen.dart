import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/primary_button.dart';
import '../onboarding_controller.dart';

const int kMinimumAge = 16;

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _locationController = TextEditingController();
  final AuthService _auth = FirebaseAuthService();
  final UserRepository _users = FirestoreUserRepository();

  DateTime? _dateOfBirth;
  bool _saving = false;
  String? _error;
  String? _dobError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _districtController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime get _maxBirthDate {
    final now = DateTime.now();
    return DateTime(now.year - kMinimumAge, now.month, now.day);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      helpText: 'Select date of birth',
      initialDate: initial.isAfter(_maxBirthDate) ? _maxBirthDate : initial,
      firstDate: DateTime(now.year - 100),
      lastDate: _maxBirthDate,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobLabel = _dateOfBirth == null
        ? 'Select your date of birth'
        : DateFormat('MMMM d, yyyy').format(_dateOfBirth!);

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
              const Text(
                'Tell us about yourself',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'We need a few details to set up your account. You must be at least 16 years old to use Aafnai Karesabari.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              TextFormField(
                  controller: _firstNameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: _required),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _lastNameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: _required),
              const SizedBox(height: 16),
              InkWell(
                onTap: _saving ? null : _pickDateOfBirth,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    errorText: _dobError,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    dobLabel,
                    style: TextStyle(
                      color: _dateOfBirth == null
                          ? Theme.of(context).hintColor
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'District'),
                validator: _required,
              ),
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
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _dobError = _dateOfBirth == null ? 'Please select your date of birth' : null;
    });
    if (!formValid || _dateOfBirth == null) return;

    if (_dateOfBirth!.isAfter(_maxBirthDate)) {
      setState(() => _dobError = 'You must be at least $kMinimumAge years old to use this app.');
      return;
    }

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
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final baseUser = AppUser(
        id: firebaseUser.uid,
        name: '$firstName $lastName'.trim(),
        phone: firebaseUser.phoneNumber ?? '',
        language: onboardingController.languageCode == 'ne'
            ? AppLanguage.ne
            : AppLanguage.en,
        email: firebaseUser.email ?? '',
        location: _locationController.text.trim(),
        district: _districtController.text.trim(),
        dateOfBirth: _dateOfBirth,
        createdAt: DateTime.now(),
        profileCompleted: true,
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
