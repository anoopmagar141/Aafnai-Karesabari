import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

/// A buyer's star rating + optional comment for a completed order,
/// left only after the buyer confirms receipt (see [Order.canBeReviewed]).
class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.consumerId,
    required this.farmerId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String orderId;
  final String consumerId;
  final String farmerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review copyWith({
    String? id,
    String? orderId,
    String? consumerId,
    String? farmerId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      consumerId: consumerId ?? this.consumerId,
      farmerId: farmerId ?? this.farmerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'order_id': orderId,
        'consumer_id': consumerId,
        'farmer_id': farmerId,
        'rating': rating,
        'comment': comment,
        'created_at': timestampToFirestore(createdAt),
      };

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return Review.fromMap(data);
  }

  factory Review.fromMap(Map<String, Object?> map) {
    return Review(
      id: map['id']! as String,
      orderId: (map['order_id'] ?? '') as String,
      consumerId: (map['consumer_id'] ?? '') as String,
      farmerId: (map['farmer_id'] ?? '') as String,
      rating: intFromFirestore(map['rating']),
      comment: map['comment'] as String?,
      createdAt: timestampFromFirestoreRequired(map['created_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Review &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            orderId == other.orderId &&
            consumerId == other.consumerId &&
            farmerId == other.farmerId &&
            rating == other.rating &&
            comment == other.comment &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        orderId,
        consumerId,
        farmerId,
        rating,
        comment,
        createdAt,
      );
}
