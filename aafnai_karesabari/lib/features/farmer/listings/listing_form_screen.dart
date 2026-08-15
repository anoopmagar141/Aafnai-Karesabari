import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/listing_icons.dart';
import '../../../data/models/listing.dart';
import '../../../shared/components/auth_text_field.dart';
import '../../../shared/components/confirmation_dialog.dart';
import '../../../data/services/listing_service.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/secondary_button.dart';
import 'add_listing_controller.dart';

/// Create/edit form for a farmer's listing: product info, pricing, and
/// the optional bargaining (minimum offer price) toggle.
class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _minBargainPriceController = TextEditingController();

  bool _loading = false;
  bool _allowBargaining = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingDraftProvider.notifier).reset();
      if (widget.listingId != null) {
        _loadListing(widget.listingId!);
      }
    });
  }

  Future<void> _loadListing(String listingId) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final listing =
          await ref.read(listingServiceProvider).getById(listingId);
      if (!mounted) return;

      if (listing == null) {
        setState(() {
          _loading = false;
          _loadError = 'Listing not found.';
        });
        return;
      }

      ref.read(listingDraftProvider.notifier).loadFromListing(listing);
      _syncControllers(ref.read(listingDraftProvider));
      setState(() => _loading = false);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Unable to load listing.';
      });
    }
  }

  void _syncControllers(ListingDraft draft) {
    _titleController.text = draft.title;
    _descriptionController.text = draft.description;
    _priceController.text =
        draft.price == null ? '' : draft.price!.toStringAsFixed(0);
    _quantityController.text =
        draft.quantity == 0 ? '' : draft.quantity.toString();
    _locationController.text = draft.location;
    _allowBargaining = draft.minBargainPrice != null;
    _minBargainPriceController.text =
        draft.minBargainPrice == null ? '' : draft.minBargainPrice!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _minBargainPriceController.dispose();
    super.dispose();
  }

  String? _farmerId() => FirebaseAuth.instance.currentUser?.uid ?? 'local-farmer';

  void _applyFormToDraft(ListingDraft draft) {
    final minBargainPrice = _allowBargaining
        ? double.tryParse(_minBargainPriceController.text.trim())
        : null;
    ref.read(listingDraftProvider.notifier).updateDraft(
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.tryParse(_priceController.text.trim()),
          quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
          category: draft.category,
          unit: draft.unit,
          location: _locationController.text,
          photoUrls: draft.photoUrls,
          minBargainPrice: minBargainPrice,
          clearMinBargainPrice: !_allowBargaining,
        );
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a product title.')),
      );
      return;
    }

    final draft = ref.read(listingDraftProvider);
    _applyFormToDraft(draft);

    final listing =
        await ref.read(listingDraftProvider.notifier).saveDraft(_farmerId()!);
    if (!mounted || listing == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved successfully')),
    );
    context.pop();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = double.tryParse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price.')),
      );
      return;
    }
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your farm location.')),
      );
      return;
    }

    final draft = ref.read(listingDraftProvider);
    _applyFormToDraft(draft);

    final listing =
        await ref.read(listingDraftProvider.notifier).publish(_farmerId()!);
    if (!mounted || listing == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing published successfully — buyers can now see it')),
    );
    context.pop();
  }

  Future<void> _deleteListing() async {
    final listingId = widget.listingId;
    if (listingId == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'Delete listing',
        message: 'This listing will be permanently removed.',
        destructive: true,
        onConfirm: () async {
          Navigator.pop(dialogContext);
          try {
            await ref.read(listingServiceProvider).deleteListing(listingId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listing deleted successfully')),
            );
            context.pop();
          } on AppException catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(listingDraftProvider);
    final isEditing = widget.listingId != null;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit listing' : 'Create listing'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit listing' : 'Create listing'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Retry',
                  onPressed: () => _loadListing(widget.listingId!),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit listing' : 'Create listing'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AuthTextField(
                label: 'Title',
                controller: _titleController,
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Enter a product title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Description',
                controller: _descriptionController,
                validator: (value) {
                  if ((value ?? '').trim().length > 500) {
                    return 'Description must be 500 characters or fewer.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ListingCategory>(
                key: ValueKey('category-${draft.category.name}'),
                initialValue: draft.category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ListingCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: draft.isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        ref
                            .read(listingDraftProvider.notifier)
                            .updateDraft(category: value);
                      },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Price (NPR)',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Quantity',
                controller: _quantityController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ListingUnit>(
                key: ValueKey('unit-${draft.unit.name}'),
                initialValue: draft.unit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ListingUnit.values
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.name),
                      ),
                    )
                    .toList(),
                onChanged: draft.isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        ref
                            .read(listingDraftProvider.notifier)
                            .updateDraft(unit: value);
                      },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Location',
                controller: _locationController,
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow buyers to make offers'),
                subtitle: const Text('Buyers can propose a lower price per unit for you to accept or reject.'),
                value: _allowBargaining,
                onChanged: draft.isSaving
                    ? null
                    : (value) => setState(() => _allowBargaining = value),
              ),
              if (_allowBargaining) ...[
                const SizedBox(height: 8),
                AuthTextField(
                  label: 'Minimum acceptable price per unit (NPR)',
                  controller: _minBargainPriceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (!_allowBargaining) return null;
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a minimum price greater than zero.';
                    }
                    final price = double.tryParse(_priceController.text.trim());
                    if (price != null && parsed > price) {
                      return 'Minimum cannot be higher than the listed price.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              _ListingIconPreview(
                titleListenable: _titleController,
                category: draft.category,
              ),
              if (draft.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  draft.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: draft.isSaving ? 'Saving...' : 'Publish listing',
                onPressed: draft.isSaving ? null : _publish,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: draft.isSaving ? 'Saving...' : 'Save draft',
                onPressed: draft.isSaving ? null : _saveDraft,
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Delete listing',
                  onPressed: draft.isSaving ? null : _deleteListing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingIconPreview extends StatelessWidget {
  const _ListingIconPreview({
    required this.titleListenable,
    required this.category,
  });

  final TextEditingController titleListenable;
  final ListingCategory category;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: titleListenable,
      builder: (context, _) {
        final icon = iconForListing(titleListenable.text, category);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'This icon represents your product in the marketplace. '
                  'It is chosen automatically from the title and category — '
                  'no photo upload needed.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
