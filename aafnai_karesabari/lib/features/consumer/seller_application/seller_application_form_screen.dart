import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/seller_application_service.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/components/primary_button.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../onboarding/profile_setup/profile_setup_screen.dart' show kMinimumAge;

/// The "become a seller" form a buyer fills out to apply; submission
/// creates a pending [SellerApplication] for an admin to review.
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
  void initState() {
    super.initState();
    _prefillAddress();
  }

  Future<void> _prefillAddress() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final user = await _userRepo.getById(userId);
    if (!mounted) return;
    if (_businessAddressController.text.isEmpty && (user?.location ?? '').isNotEmpty) {
      setState(() => _businessAddressController.text = user!.location!);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  /// Navigates away from this screen. Settings routes here with context.go(),
  /// which replaces the stack entirely, so there is nothing to pop back to —
  /// context.pop() would throw. Fall back to Home in that case.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.consumerHome);
    }
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
      _leave();
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

  /// Sellers must be at least [kMinimumAge]. Ordinary profile edits don't
  /// enforce this — it's only checked here, at the point the user actually
  /// wants to become a seller.
  bool _isOldEnough(AppUser user) {
    final dob = user.dateOfBirth;
    if (dob == null) return false;
    final now = DateTime.now();
    final maxBirthDate = DateTime(now.year - kMinimumAge, now.month, now.day);
    return !dob.isAfter(maxBirthDate);
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

          if (user != null && !_isOldEnough(user)) {
            return _buildStatusMessage(
              icon: Icons.verified_user_outlined,
              color: Colors.orange,
              title: 'Age Verification Required',
              message: user.dateOfBirth == null
                  ? 'Sellers must be at least $kMinimumAge years old. Please add your date of birth in Edit Profile, then come back to apply.'
                  : 'You must be at least $kMinimumAge years old to become a seller.',
              actionLabel: 'Go to Edit Profile',
              onAction: () => context.push(AppRoutes.editProfile),
            );
          }

          return _buildForm();
        },
      ),
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
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
            if (actionLabel != null && onAction != null) ...[
              PrimaryButton(label: actionLabel, onPressed: onAction),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: _leave,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
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
