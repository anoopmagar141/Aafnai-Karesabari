import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/auth_service.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/auth_text_field.dart';
import '../../../shared/components/primary_button.dart';

/// Sends a Firebase password-reset email to the address the user enters.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _auth = FirebaseAuthService();
  bool _submitting = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text('Forgot your password?',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Enter your email and we will send you a reset link.'),
                const SizedBox(height: 24),
                AuthTextField(
                  label: 'Email address',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                if (_message != null) ...[
                  Text(
                    _message!,
                    style: TextStyle(
                        color: _isSuccess ? Colors.green : Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                    label: _submitting ? 'Sending...' : 'Send reset link',
                    onPressed: _submitting ? null : _submit),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Back to sign in')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        _isSuccess = true;
        _message = 'Password reset email sent. Check your inbox.';
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _isSuccess = false;
        _message = _firebaseMessage(error);
      });
    } catch (_) {
      setState(() {
        _isSuccess = false;
        _message = 'Could not send the reset email. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

  String _firebaseMessage(FirebaseAuthException error) => switch (error.code) {
        'invalid-email' => 'Please enter a valid email address.',
        'user-not-found' => 'No account found for that email.',
        _ => error.message ?? 'Could not send the reset email.',
      };
}
