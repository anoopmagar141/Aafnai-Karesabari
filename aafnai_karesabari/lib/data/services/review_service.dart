import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../models/review.dart';
import '../repositories/order_repository.dart';
import '../repositories/review_repository.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

/// Creates a buyer's review for a completed order, enforcing that only
/// the actual buyer of a delivered order can review it once.
class ReviewService {
  ReviewService({
    ReviewRepository? reviewRepository,
    ReviewRepository? localReviewRepository,
    OrderRepository? orderRepository,
    OrderRepository? localOrderRepository,
  })  : _reviewRepository = reviewRepository ?? FirestoreReviewRepository(),
        _localReviewRepository = localReviewRepository ?? LocalReviewRepository(),
        _orderRepository = orderRepository ?? FirestoreOrderRepository(),
        _localOrderRepository = localOrderRepository ?? LocalOrderRepository();

  final ReviewRepository _reviewRepository;
  final ReviewRepository _localReviewRepository;
  final OrderRepository _orderRepository;
  final OrderRepository _localOrderRepository;

  Future<Review> createReview({
    required String orderId,
    required String consumerId,
    required String farmerId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const AppException('Rating must be between 1 and 5.');
    }

    final order = await _runOrder((repository) => repository.getById(orderId));
    if (order == null) {
      throw const AppException('Order not found.');
    }
    if (order.consumerId != consumerId) {
      throw const AppException('Only the buyer may review this order.');
    }
    if (!order.canBeReviewed) {
      throw const AppException('Only delivered orders can be reviewed.');
    }

    final existingReviews = await listReviews(orderId: orderId, consumerId: consumerId);
    if (existingReviews.isNotEmpty) {
      throw const AppException('You have already reviewed this order.');
    }

    final review = Review(
      id: 'review-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      consumerId: consumerId,
      farmerId: farmerId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    return _runReview((repository) => repository.create(review));
  }

  Future<List<Review>> listReviews({
    String? orderId,
    String? consumerId,
    String? farmerId,
    int? limit,
  }) async {
    return _runReview((repository) => repository.list(
          filter: ReviewListFilter(
            orderId: orderId,
            consumerId: consumerId,
            farmerId: farmerId,
            limit: limit,
          ),
        ));
  }

  Future<Review?> getReviewById(String reviewId) async {
    return _runReview((repository) => repository.getById(reviewId));
  }

  Future<T> _runReview<T>(Future<T> Function(ReviewRepository repository) action) async {
    try {
      return await action(_reviewRepository);
    } on AppException catch (error) {
      // See NotificationService for why this is logged: silently falling
      // back to the (empty) local cache hides real bugs like a missing
      // Firestore composite index behind an innocent "no reviews yet".
      debugPrint('ReviewService: Firestore call failed, falling back to local cache: $error');
      return await action(_localReviewRepository);
    }
  }

  Future<T> _runOrder<T>(Future<T> Function(OrderRepository repository) action) async {
    try {
      return await action(_orderRepository);
    } on AppException {
      return await action(_localOrderRepository);
    }
  }
}
