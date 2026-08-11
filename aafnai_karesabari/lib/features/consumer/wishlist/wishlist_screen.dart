import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/listing.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../data/services/wishlist_service.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/error_state.dart';
import '../../../shared/components/product_card.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  List<String>? _loadedForIds;
  Future<List<Listing>>? _future;
  Object? _lastError;

  Future<List<Listing>> _loadWishlist(List<String> ids) async {
    final repo = ref.read(listingRepositoryProvider);
    final results = <Listing>[];
    for (final id in ids) {
      try {
        final listing = await repo.getById(id);
        if (listing != null) results.add(listing);
      } catch (_) {
        // One bad/unreachable listing shouldn't blank out the rest of the
        // wishlist — skip it and keep going.
      }
    }
    return results;
  }

  void _ensureLoaded(List<String> ids) {
    if (_loadedForIds != null && _listEquals(_loadedForIds!, ids)) return;
    _loadedForIds = ids;
    _lastError = null;
    _future = _loadWishlist(ids).catchError((error) {
      _lastError = error;
      return const <Listing>[];
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _retry() {
    setState(() {
      _loadedForIds = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlistIds = ref.watch(wishlistNotifierProvider);
    _ensureLoaded(wishlistIds);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: wishlistIds.isEmpty
          ? _buildEmptyState(context)
          : FutureBuilder<List<Listing>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_lastError != null) {
                  return ErrorState(
                    title: 'Could not load your wishlist',
                    message: 'Please check your connection and try again.',
                    onRetry: _retry,
                  );
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
