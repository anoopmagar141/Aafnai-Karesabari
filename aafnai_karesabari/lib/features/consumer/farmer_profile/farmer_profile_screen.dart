import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/listing.dart';
import '../../../data/models/review.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../data/services/review_service.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/product_card.dart';

/// A public storefront view of one farmer: their info plus a grid of
/// their active listings, reached by tapping a seller's name anywhere
/// in the app.
class FarmerProfileScreen extends ConsumerStatefulWidget {
  const FarmerProfileScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  ConsumerState<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends ConsumerState<FarmerProfileScreen> {
  late final Future<List<Listing>> _listingsFuture;
  late final Future<AppUser?> _farmerFuture;
  late final Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = ref.read(listingServiceProvider).listForFarmer(widget.farmerId);
    _farmerFuture = FirestoreUserRepository().getById(widget.farmerId);
    _reviewsFuture = ref.read(reviewServiceProvider).listReviews(farmerId: widget.farmerId, limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer profile')),
      body: FutureBuilder<List<Listing>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data ?? const <Listing>[];
          if (listings.isEmpty) {
            return const EmptyState(
              icon: Icons.person_outline,
              title: 'Farmer has no listings yet',
              subtitle: 'Please check back later for fresh produce.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileCard(),
              const SizedBox(height: 16),
              const Text('Fresh picks', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) => ProductCard(
                  listing: listings[index],
                  onTap: () => context.push('/consumer/product/${listings[index].id}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<AppUser?>(
          future: _farmerFuture,
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;
            final displayName = _firstNonEmpty([user?.businessName, user?.name]) ?? 'Local farmer';
            final description = _firstNonEmpty([user?.businessDescription, user?.bio]);
            final location = _firstNonEmpty([
              user?.farmAddress,
              [user?.district, user?.province].where((p) => p != null && p.isNotEmpty).join(', '),
              user?.location,
            ]);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  description ??
                      (location != null
                          ? 'Fresh produce delivered directly from $location.'
                          : 'Fresh produce delivered directly from this farm.'),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                if (location != null && description != null) ...[
                  const SizedBox(height: 4),
                  Text(location, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                FutureBuilder<List<Review>>(
                  future: _reviewsFuture,
                  builder: (context, reviewSnapshot) {
                    final reviews = reviewSnapshot.data ?? const <Review>[];
                    if (reviews.isEmpty) {
                      return const Text(
                        'No ratings yet',
                        style: TextStyle(color: AppColors.textMuted),
                      );
                    }
                    final avgRating =
                        reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
                    return Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 18),
                        const SizedBox(width: 4),
                        Text('${avgRating.toStringAsFixed(1)} • ${reviews.length} '
                            '${reviews.length == 1 ? 'review' : 'reviews'}'),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
