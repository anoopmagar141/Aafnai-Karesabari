import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/review.dart';
import '../../../data/services/review_service.dart';
import 'add_review_dialog.dart';

class RatingsSection extends ConsumerStatefulWidget {
  final String farmerId;
  final String productId;

  const RatingsSection({
    super.key,
    required this.farmerId,
    required this.productId,
  });

  @override
  ConsumerState<RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends ConsumerState<RatingsSection> {
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = ref.read(reviewServiceProvider).listReviews(
          farmerId: widget.farmerId,
          limit: 10,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final reviews = snapshot.data ?? [];
        final avgRating =
            reviews.isEmpty ? 0.0 : reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reviews', style: AppTypography.sectionTitle),
                  const SizedBox(height: 12),
                  // Rating Summary
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStarRating(avgRating, size: 16),
                          const SizedBox(height: 4),
                          Text(
                            '${reviews.length} review${reviews.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (context) => AddReviewDialog(
                              farmerId: widget.farmerId,
                              onReviewAdded: () {
                                setState(_loadReviews);
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_border),
                        label: const Text('Add review'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Reviews List
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (_, index) => _buildReviewCard(reviews[index]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarRating(review.rating.toDouble(), size: 14),
                  const SizedBox(height: 4),
                  Text(
                    'By User',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              dateFormat.format(review.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        if (review.comment != null) ...[
          const SizedBox(height: 8),
          Text(
            review.comment!,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
