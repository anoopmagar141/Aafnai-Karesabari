import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../shared/components/primary_button.dart';
import '../onboarding_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.role});
  final SelectedRole role;
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  @override
  void dispose() { _nameController.dispose(); _locationController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final farmer = widget.role == SelectedRole.farmer;
    return Scaffold(appBar: AppBar(title: Text(farmer ? 'Set up your farm' : 'Set up your profile')), body: SafeArea(child: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(24), children: [
      CircleAvatar(radius: 42, child: Icon(farmer ? Icons.agriculture : Icons.person, size: 40)),
      const SizedBox(height: 24),
      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Your name'), validator: _required),
      const SizedBox(height: 16),
      TextFormField(controller: _locationController, decoration: InputDecoration(labelText: farmer ? 'Farm district' : 'Delivery address'), validator: _required),
      const SizedBox(height: 24),
      PrimaryButton(label: 'Continue', onPressed: () { if (!(_formKey.currentState?.validate() ?? false)) return; onboardingController.completeProfile(); context.go(farmer ? AppRoutes.farmerHome : AppRoutes.consumerHome); }),
    ]))));
  }
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;
}
