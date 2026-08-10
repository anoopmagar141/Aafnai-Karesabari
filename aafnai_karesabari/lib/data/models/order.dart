import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/firestore_helpers.dart';

enum OrderStatus { pending, accepted, rejected, cancelled, completed }

class Order {
  const Order({
    required this.id,
    required this.consumerId,
    required this.farmerId,
    required this.listingId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.commissionAmount,
    this.farmerPayout,
  });

  final String id;
  final String consumerId;
  final String farmerId;
  final String listingId;
  final double quantity;
  final double totalPrice;

  /// These are server-generated display values; client code must not calculate or persist them.
  final double? commissionAmount;
  final double? farmerPayout;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canBeCancelled => status == OrderStatus.pending;
  bool get canBeReviewed => status == OrderStatus.completed;

  Order copyWith({
    String? id,
    String? consumerId,
    String? farmerId,
    String? listingId,
    double? quantity,
    double? totalPrice,
    double? commissionAmount,
    double? farmerPayout,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      farmerId: farmerId ?? this.farmerId,
      listingId: listingId ?? this.listingId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      farmerPayout: farmerPayout ?? this.farmerPayout,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'consumer_id': consumerId,
        'farmer_id': farmerId,
        'listing_id': listingId,
        'quantity': quantity,
        'total_price': totalPrice,
        'commission_amount': commissionAmount,
        'farmer_payout': farmerPayout,
        'status': status.name,
        'created_at': timestampToFirestore(createdAt),
        'updated_at': timestampToFirestore(updatedAt),
      };

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return Order.fromMap(data);
  }

  factory Order.fromMap(Map<String, Object?> map) {
    return Order(
      id: map['id']! as String,
      consumerId: (map['consumer_id'] ?? '') as String,
      farmerId: (map['farmer_id'] ?? '') as String,
      listingId: (map['listing_id'] ?? '') as String,
      quantity: doubleFromFirestore(map['quantity']),
      totalPrice: doubleFromFirestore(map['total_price']),
      commissionAmount: map['commission_amount'] == null
          ? null
          : doubleFromFirestore(map['commission_amount']),
      farmerPayout: map['farmer_payout'] == null
          ? null
          : doubleFromFirestore(map['farmer_payout']),
      status: OrderStatus.values.byName(map['status']! as String),
      createdAt: timestampFromFirestoreRequired(map['created_at']),
      updatedAt: timestampFromFirestoreRequired(map['updated_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Order &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            consumerId == other.consumerId &&
            farmerId == other.farmerId &&
            listingId == other.listingId &&
            quantity == other.quantity &&
            totalPrice == other.totalPrice &&
            commissionAmount == other.commissionAmount &&
            farmerPayout == other.farmerPayout &&
            status == other.status &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        consumerId,
        farmerId,
        listingId,
        quantity,
        totalPrice,
        commissionAmount,
        farmerPayout,
        status,
        createdAt,
        updatedAt,
      );
}
