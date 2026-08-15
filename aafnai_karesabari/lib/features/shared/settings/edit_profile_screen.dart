import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/components/primary_button.dart';
import '../../onboarding/profile_setup/profile_setup_screen.dart' show kMinimumAge;

/// Edit form for the signed-in user's own profile fields (name, phone,
/// location, and — for sellers — business info).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepo = FirestoreUserRepository();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _bioController = TextEditingController();

  // Seller-only business fields
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _farmAddressController = TextEditingController();
  final _businessHoursController = TextEditingController();

  AppUser? _user;
  DateTime? _dateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _dobError;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userRepo.getById(_userId);
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _locationController.text = user.location ?? '';
        _districtController.text = user.district ?? '';
        _provinceController.text = user.province ?? '';
        _bioController.text = user.bio ?? '';
        _businessNameController.text = user.businessName ?? '';
        _businessDescriptionController.text = user.businessDescription ?? '';
        _farmAddressController.text = user.farmAddress ?? '';
        _businessHoursController.text = user.businessHours ?? '';
        _dateOfBirth = user.dateOfBirth;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _bioController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _farmAddressController.dispose();
    _businessHoursController.dispose();
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

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid || _user == null) return;

    // Date of birth is optional here — it's captured (and age-verified)
    // during account creation, and again if the user later applies to
    // become a seller. Editing an existing profile shouldn't re-impose
    // that check; only guard against an obviously invalid edit if the
    // user chooses to change it.
    if (_dateOfBirth != null && _dateOfBirth!.isAfter(_maxBirthDate)) {
      setState(() => _dobError = 'You must be at least $kMinimumAge years old to use this app.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updated = _user!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        district: _districtController.text.trim(),
        province: _provinceController.text.trim(),
        bio: _bioController.text.trim(),
        dateOfBirth: _dateOfBirth,
        businessName: _user!.isSeller ? _businessNameController.text.trim() : null,
        businessDescription:
            _user!.isSeller ? _businessDescriptionController.text.trim() : null,
        farmAddress: _user!.isSeller ? _farmAddressController.text.trim() : null,
        businessHours: _user!.isSeller ? _businessHoursController.text.trim() : null,
      );
      await _userRepo.update(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Failed to load profile.'))
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text('Personal information',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone number'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _user!.email,
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Email (cannot be changed)'),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _isSaving ? null : _pickDateOfBirth,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date of birth (optional)',
                              errorText: _dobError,
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              _dateOfBirth == null
                                  ? 'Not set'
                                  : DateFormat('MMMM d, yyyy').format(_dateOfBirth!),
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
                          controller: _locationController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(labelText: 'Delivery address / location'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _districtController,
                                enabled: !_isSaving,
                                decoration: const InputDecoration(labelText: 'District'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _provinceController,
                                enabled: !_isSaving,
                                decoration: const InputDecoration(labelText: 'Province'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          enabled: !_isSaving,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Bio'),
                        ),
                        if (_user!.isSeller) ...[
                          const SizedBox(height: 32),
                          Text('Business information',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessNameController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(labelText: 'Business / farm name'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessDescriptionController,
                            enabled: !_isSaving,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Business description'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _farmAddressController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(labelText: 'Farm / business address'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessHoursController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(labelText: 'Business hours'),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: _isSaving ? 'Saving...' : 'Save changes',
                          onPressed: _isSaving ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
