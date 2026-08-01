import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/services/secure_token_store.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/auth_text_field.dart';
import '../../../shared/components/primary_button.dart';
import '../onboarding_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = FirebaseAuthService();
  final SecureTokenStore _tokenStore = SecureTokenStore();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text('Welcome back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Use your email and password to continue.'),
              const SizedBox(height: 24),
              AuthTextField(
                label: 'Email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                  label: _submitting ? 'Signing in...' : 'Sign in',
                  onPressed: _submitting ? null : _signIn),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?')),
              TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text('Create an account')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        _showError('Unable to sign in right now.');
        return;
      }

      final token = await _auth.currentIdToken();
      if (token != null) {
        await _tokenStore.saveSessionToken(token);
      }

      onboardingController.authenticate(user.email ?? email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully.')));
      // Router automatically redirects based on authStateChanges
    } on FirebaseAuthException catch (error) {
      _showError(_firebaseMessage(error));
    } catch (_) {
      _showError('Could not sign in. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _firebaseMessage(FirebaseAuthException error) => switch (error.code) {
        'invalid-email' => 'Please enter a valid email address.',
        'user-not-found' => 'No account found for that email.',
        'wrong-password' => 'The password is incorrect.',
        'invalid-credential' => 'Incorrect email or password.',
        'user-disabled' => 'This account has been disabled.',
        _ => error.message ?? 'Could not sign in. Please try again.',
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
