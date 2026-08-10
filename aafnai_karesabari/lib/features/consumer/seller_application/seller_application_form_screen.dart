import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/seller_application_service.dart';
import '../../../shared/components/primary_button.dart';
import '../../onboarding/onboarding_controller.dart';

class SellerApplicationFormScreen extends ConsumerStatefulWidget {
  const SellerApplicationFormScreen({super.key});

  @override
  ConsumerState<SellerApplicationFormScreen> createState() =>
      _SellerApplicationFormScreenState();
}

class _SellerApplicationFormScreenState
    extends ConsumerState<SellerApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final UserRepository _userRepo = FirestoreUserRepository();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw StateError('You must be signed in to apply.');
      }

      await ref.read(sellerApplicationServiceProvider).submitApplication(
            applicantId: userId,
            businessName: _businessNameController.text,
            businessDescription: _businessDescriptionController.text,
            businessAddress: _businessAddressController.text,
          );

      await onboardingController.refreshProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted! We will review it shortly.')),
      );
      context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Become a Seller')),
      body: StreamBuilder<AppUser?>(
        stream: _userRepo.stream(userId),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user != null && user.sellerStatus == 'pending') {
            return _buildStatusMessage(
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              title: 'Application Under Review',
              message: 'We\'re reviewing your seller application. This usually takes 1-2 days.',
            );
          }

          if (user != null && user.sellerStatus == 'approved') {
            return _buildStatusMessage(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              title: 'You\'re Already a Seller!',
              message: 'Your seller account is approved. Go to your seller dashboard to get started.',
            );
          }

          return _buildForm(user);
        },
      ),
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppUser? user) {
    if (user != null && (_businessAddressController.text.isEmpty) &&
        (user.location ?? '').isNotEmpty) {
      _businessAddressController.text = user.location!;
    }

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Tell us about your farm or business',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'This information helps us verify sellers and will be shown on your public profile.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _businessNameController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Business / Farm name',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessDescriptionController,
              enabled: !_isSubmitting,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe what you sell',
                hintText: 'e.g. Organic vegetables grown in Lalitpur, fresh seasonal fruits...',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessAddressController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Farm / business address',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isSubmitting ? 'Submitting...' : 'Submit application',
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
