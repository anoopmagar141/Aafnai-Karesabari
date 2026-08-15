import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/auth_text_field.dart';
import '../../../shared/components/primary_button.dart';
import '../onboarding_controller.dart';
import '../profile_setup/profile_setup_screen.dart' show kMinimumAge;

/// New-account sign-up form: creates the Firebase Auth user and their
/// initial `users/{uid}` profile document.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _districtController = TextEditingController();
  final _locationController = TextEditingController();
  final AuthService _auth = FirebaseAuthService();
  final UserRepository _users =
      FirestoreUserRepository(firestore: FirebaseFirestore.instance);
  bool _submitting = false;
  String? _error;
  DateTime? _dateOfBirth;
  String? _dobError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text('Create your account',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Join Aafnai Karesabari. You must be at least $kMinimumAge years old to sign up.'),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'First name',
                        controller: _firstNameController,
                        validator: _validateFirstName,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        label: 'Last name',
                        controller: _lastNameController,
                        validator: _validateLastName,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Email address',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Phone number',
                  controller: _phoneController,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Password',
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Confirm password',
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  obscureText: true,
                  prefixIcon: Icons.lock_reset,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _submitting ? null : _pickDateOfBirth,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of birth',
                      errorText: _dobError,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                AuthTextField(
                  label: 'District',
                  controller: _districtController,
                  validator: _required,
                  prefixIcon: Icons.location_city_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Delivery address',
                  controller: _locationController,
                  validator: _required,
                  prefixIcon: Icons.home_outlined,
                  textInputAction: TextInputAction.done,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                    label:
                        _submitting ? 'Creating account...' : 'Create account',
                    onPressed: _submitting ? null : _submit),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Already have an account? Login')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _dobError = _dateOfBirth == null ? 'Please select your date of birth' : null;
    });
    if (!formValid || _dateOfBirth == null) return;

    if (_dateOfBirth!.isAfter(_maxBirthDate)) {
      setState(() =>
          _dobError = 'You must be at least $kMinimumAge years old to use this app.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = userCredential.user;
      if (user == null) {
        _showError('Unable to create your account right now.');
        return;
      }
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      await _users.save(AppUser(
        id: user.uid,
        name: fullName,
        phone: _phoneController.text.trim(),
        language: onboardingController.languageCode == 'ne'
            ? AppLanguage.ne
            : AppLanguage.en,
        email: user.email ?? _emailController.text.trim(),
        location: _locationController.text.trim(),
        district: _districtController.text.trim(),
        dateOfBirth: _dateOfBirth,
        createdAt: DateTime.now(),
        profileCompleted: true,
      ));
      await onboardingController.syncWithAuthState(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully.')));
      context.go(AppRoutes.consumerHome);
    } on FirebaseAuthException catch (error) {
      _showError(_firebaseMessage(error));
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your first name.';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your last name.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email address.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return 'Please enter your phone number.';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s]{7,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _firebaseMessage(FirebaseAuthException error) => switch (error.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'operation-not-allowed' => 'Email/password sign-up is not enabled.',
        'weak-password' => 'Please choose a stronger password.',
        _ => error.message ?? 'Could not create your account.',
      };

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _submitting = false;
      });
    }
  }
}
