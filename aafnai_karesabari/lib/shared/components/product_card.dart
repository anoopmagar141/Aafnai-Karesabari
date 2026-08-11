import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/models/review.dart';
import '../../data/services/review_service.dart';
import '../../data/services/wishlist_service.dart';
import 'status_badge.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.featured = false,
  });

  final Listing listing;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Icon(
                      listing.displayIcon,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  if (featured)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: StatusBadge(
                        label: 'Featured',
                        color: AppColors.accent,
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final isWish =
                            ref.watch(wishlistNotifierProvider).contains(listing.id);
                        return IconButton(
                          icon: Icon(
                            isWish ? Icons.favorite : Icons.favorite_border,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(wishlistNotifierProvider.notifier)
                                  .toggle(listing.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not update wishlist: $e')),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle,
                  ),
                  Text(
                    '${formatNpr(listing.pricePerUnit)} / ${listing.unit.name}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildRatingBadge(ref, listing.farmerId),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textMuted),
                      Text(
                        'Local farm',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(WidgetRef ref, String farmerId) {
    return FutureBuilder<List<Review>>(
      future: ref.read(reviewServiceProvider).listReviews(
            farmerId: farmerId,
            limit: 100,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'No ratings yet',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          );
        }

        final reviews = snapshot.data!;
        final avgRating =
            reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;

        return Row(
          children: [
            Icon(Icons.star, size: 14, color: AppColors.accent),
            const SizedBox(width: 3),
            Text(
              '${avgRating.toStringAsFixed(1)} (${reviews.length})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}
