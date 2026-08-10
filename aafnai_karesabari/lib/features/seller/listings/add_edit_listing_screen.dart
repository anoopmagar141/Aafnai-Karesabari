import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/seller_listing.dart';
import '../../../data/repositories/seller_listing_repository.dart';

class AddEditListingScreen extends ConsumerStatefulWidget {
  const AddEditListingScreen({super.key, this.listingId});

  final String? listingId;

  @override
  ConsumerState<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends ConsumerState<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) {
      _loadListing(widget.listingId!);
    }
  }

  Future<void> _loadListing(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = SellerListingRepository();
      final listing = await repo.getById(id);
      if (!mounted) return;
      if (listing == null) {
        setState(() => _error = 'Listing not found');
        return;
      }
      // Populate controllers
      _productNameController.text = listing.productName;
      _descriptionController.text = listing.description;
      _priceController.text = listing.price.toString();
      _quantityController.text = listing.quantity.toString();
      _unitController.text = listing.unit;
      _categoryController.text = listing.category;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final repo = SellerListingRepository();
    final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    try {
      if (widget.listingId == null) {
        // create new
        final newListing = SellerListing(
          id: '', // placeholder, repository will set
          sellerId: sellerId,
          sellerName: '', // could fetch from profile later
          productName: _productNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          unit: _unitController.text.trim(),
          imageUrls: [],
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(newListing);
      } else {
        // update existing
        final existing = await repo.getById(widget.listingId!);
        if (existing == null) throw Exception('Listing missing');
        final updated = existing.copyWith(
          productName: _productNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          unit: _unitController.text.trim(),
          updatedAt: now,
        );
        await repo.update(updated);
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.listingId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Listing' : 'Add Listing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _productNameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid price' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter a valid quantity' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: Text(isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
