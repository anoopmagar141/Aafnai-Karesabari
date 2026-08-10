import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/listing.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  Future<List<Listing>> _loadWishlist(WidgetRef ref) async {
    final ids = ref.watch(wishlistNotifierProvider);
    if (ids.isEmpty) return [];
    final repo = ref.read(listingRepositoryProvider);
    final futures = ids.map((id) => repo.getById(id));
    final results = await Future.wait(futures);
    return results.whereType<Listing>().toList(growable: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: wishlistIds.isEmpty
          ? _buildEmptyState(context)
          : FutureBuilder<List<Listing>>(
              future: _loadWishlist(ref),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final listings = snapshot.data ?? const <Listing>[];
                if (listings.isEmpty) {
                  return _buildEmptyState(context);
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (_, index) {
                    final listing = listings[index];
                    return ProductCard(
                      listing: listing,
                      onTap: () => context.go('/consumer/product/${listing.id}'),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.favorite_border,
              title: 'Your Wishlist is Empty',
              subtitle: 'Save products you like and find them later.',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.consumerHome),
              child: const Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }
}
