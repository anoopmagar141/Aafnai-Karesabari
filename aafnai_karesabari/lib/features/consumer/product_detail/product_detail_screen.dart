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

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late final Future<Listing?> _listingFuture;

  @override
  void initState() {
    super.initState();
    _listingFuture = ref.read(listingServiceProvider).getById(widget.productId);
  }

  Future<void> _addToCart(Listing listing) async {
    await ref.read(cartServiceProvider).addItem(listingId: listing.id);
    await ref.read(cartCountProvider.notifier).refreshCartCount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to your basket')),
    );
    context.go(AppRoutes.cart);
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
}
