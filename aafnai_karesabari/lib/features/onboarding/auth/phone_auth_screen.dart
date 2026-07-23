import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../shared/components/primary_button.dart';
import '../onboarding_controller.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key, required this.otpStep});
  final bool otpStep;
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.otpStep;
    return Scaffold(
      appBar: AppBar(title: Text(otp ? 'Verify your number' : 'Sign in with phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(otp ? 'Enter the 4-digit code sent to your phone.' : 'Enter your Nepali mobile number to receive a verification code.'),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                maxLength: otp ? 4 : null,
                decoration: InputDecoration(labelText: otp ? 'Verification code' : 'Phone number', prefixText: otp ? null : '+977 '),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: otp ? 'Verify' : 'Send OTP',
                onPressed: () {
                  if (_controller.text.trim().isEmpty) return;
                  if (otp) {
                    onboardingController.verifyOtp();
                    context.go(onboardingController.role == SelectedRole.farmer ? AppRoutes.farmerSetup : AppRoutes.consumerSetup);
                  } else {
                    context.go(AppRoutes.otp);
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Phase 1 uses local flow validation only. Firebase OTP will replace this in Phase 2.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
