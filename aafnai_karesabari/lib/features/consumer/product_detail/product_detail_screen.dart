import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/listing.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/listing_service.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/farmer_card.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/status_badge.dart';
import 'ratings_section.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late final Future<Listing?> _listingFuture;
  final _offerController = TextEditingController();
  bool _makingOffer = false;
  String? _offerError;

  @override
  void initState() {
    super.initState();
    _listingFuture = ref.read(listingServiceProvider).getById(widget.productId);
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(Listing listing, {double? offeredPricePerUnit}) async {
    await ref.read(cartServiceProvider).addItem(
          listingId: listing.id,
          offeredPricePerUnit: offeredPricePerUnit,
        );
    await ref.read(cartCountProvider.notifier).refreshCartCount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(offeredPricePerUnit != null
            ? 'Offer added to your basket'
            : 'Added to your basket'),
      ),
    );
    context.go(AppRoutes.cart);
  }

  void _submitOffer(Listing listing) {
    final offer = double.tryParse(_offerController.text.trim());
    final min = listing.minBargainPrice!;
    if (offer == null || offer <= 0) {
      setState(() => _offerError = 'Enter a valid price.');
      return;
    }
    if (offer >= listing.pricePerUnit) {
      setState(() => _offerError =
          'Enter an amount below the listed price of NPR ${listing.pricePerUnit.toStringAsFixed(0)}.');
      return;
    }
    if (offer < min) {
      setState(() =>
          _offerError = 'The seller won\'t accept less than NPR ${min.toStringAsFixed(0)}.');
      return;
    }
    setState(() => _offerError = null);
    _addToCart(listing, offeredPricePerUnit: offer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: FutureBuilder<Listing?>(
        future: _listingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final listing = snapshot.data;
          if (listing == null) {
            return const Center(child: Text('This product is no longer available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: AppColors.softGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          listing.displayIcon,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(listing.productName, style: AppTypography.screenTitle),
                      Text(
                        'NPR ${listing.pricePerUnit.toStringAsFixed(0)} / ${listing.unit.name}',
                        style: AppTypography.price.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(
                        label: listing.stockQuantity > 0 ? 'In stock' : 'Out of stock',
                        color: listing.stockQuantity > 0 ? AppColors.primary : AppColors.accent,
                      ),
                      const SizedBox(height: 12),
                      if (listing.description != null)
                        Text(listing.description!, style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 20),
                      Text('Location: ${listing.location ?? 'Lalitpur'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Quantity available: ${listing.stockQuantity}', style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => context.push('/consumer/farmer/${listing.farmerId}'),
                        child: FarmerCard(
                          name: listing.farmerId.toUpperCase(),
                          district: listing.location ?? 'Lalitpur',
                        ),
                      ),
                      if (listing.acceptsBargaining && listing.stockQuantity > 0) ...[
                        const SizedBox(height: 24),
                        _buildBargainSection(listing),
                      ],
                      const SizedBox(height: 24),
                      RatingsSection(
                        farmerId: listing.farmerId,
                        productId: listing.id,
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: 'Add to basket',
                  onPressed: listing.stockQuantity > 0 ? () => _addToCart(listing) : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBargainSection(Listing listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Make an offer', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'This seller accepts offers below the listed price. Send yours and they\'ll accept or decline.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (!_makingOffer)
            OutlinedButton.icon(
              onPressed: () => setState(() => _makingOffer = true),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Propose a price'),
            )
          else ...[
            TextField(
              controller: _offerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Your offer per ${listing.unit.name} (NPR)',
                errorText: _offerError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _makingOffer = false;
                      _offerError = null;
                      _offerController.clear();
                    }),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitOffer(listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add offer to basket'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
