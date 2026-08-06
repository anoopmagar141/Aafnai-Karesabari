import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';
import 'firestore_repository.dart';

class ReviewListFilter {
  const ReviewListFilter({
    this.orderId,
    this.consumerId,
    this.farmerId,
    this.limit,
  });

  final String? orderId;
  final String? consumerId;
  final String? farmerId;
  final int? limit;
}

abstract class ReviewRepository {
  Future<Review> create(Review review);
  Future<void> update(Review review);
  Future<void> delete(String reviewId);
  Future<Review?> getById(String reviewId);
  Stream<Review?> stream(String reviewId);
  Future<List<Review>> list({ReviewListFilter? filter});
}

class FirestoreReviewRepository implements ReviewRepository {
  FirestoreReviewRepository({FirebaseFirestore? firestore})
      : _reviews =
            (firestore ?? FirebaseFirestore.instance).collection('reviews');

  final CollectionReference<Map<String, dynamic>> _reviews;

  @override
  Future<Review> create(Review review) => runFirestore(() async {
        await _reviews.doc(review.id).set(review.toFirestore());
        return review;
      }, message: 'Unable to create review.');

  @override
  Future<void> update(Review review) => runFirestore(
        () => _reviews
            .doc(review.id)
            .set(review.toFirestore(), SetOptions(merge: true)),
        message: 'Unable to update review.',
      );

  @override
  Future<void> delete(String reviewId) => runFirestore(
        () => _reviews.doc(reviewId).delete(),
        message: 'Unable to delete review.',
      );

  @override
  Future<Review?> getById(String reviewId) => runFirestore(() async {
        final snapshot = await _reviews.doc(reviewId).get();
        if (!snapshot.exists) return null;
        return Review.fromFirestore(snapshot);
      }, message: 'Unable to load review.');

  @override
  Stream<Review?> stream(String reviewId) {
    return mapDocumentStream(_reviews.doc(reviewId), Review.fromFirestore);
  }

  @override
  Future<List<Review>> list({ReviewListFilter? filter}) =>
      runFirestore(() async {
        Query<Map<String, dynamic>> query =
            _reviews.orderBy('created_at', descending: true);

        final orderId = filter?.orderId;
        if (orderId != null) {
          query = query.where('order_id', isEqualTo: orderId);
        }

        final consumerId = filter?.consumerId;
        if (consumerId != null) {
          query = query.where('consumer_id', isEqualTo: consumerId);
        }

        final farmerId = filter?.farmerId;
        if (farmerId != null) {
          query = query.where('farmer_id', isEqualTo: farmerId);
        }

        final limit = filter?.limit;
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, Review.fromFirestore);
      }, message: 'Unable to load reviews.');
}

class LocalReviewRepository implements ReviewRepository {
  final Map<String, Review> _reviews = {};

  @override
  Future<Review> create(Review review) async {
    _reviews[review.id] = review;
    return review;
  }

  @override
  Future<void> update(Review review) async {
    _reviews[review.id] = review;
  }

  @override
  Future<void> delete(String reviewId) async {
    _reviews.remove(reviewId);
  }

  @override
  Future<Review?> getById(String reviewId) async => _reviews[reviewId];

  @override
  Stream<Review?> stream(String reviewId) async* {
    yield _reviews[reviewId];
  }

  @override
  Future<List<Review>> list({ReviewListFilter? filter}) async {
    var results = _reviews.values.toList();
    final orderId = filter?.orderId;
    if (orderId != null) {
      results = results.where((review) => review.orderId == orderId).toList();
    }
    final consumerId = filter?.consumerId;
    if (consumerId != null) {
      results =
          results.where((review) => review.consumerId == consumerId).toList();
    }
    final farmerId = filter?.farmerId;
    if (farmerId != null) {
      results = results.where((review) => review.farmerId == farmerId).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limit = filter?.limit;
    if (limit != null) {
      return results.take(limit).toList(growable: false);
    }
    return results;
  }
}
