import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

class MarketPrice {
  const MarketPrice({
    required this.id,
    required this.productName,
    required this.region,
    required this.low,
    required this.average,
    required this.high,
    required this.recordedAt,
  });

  final String id;
  final String productName;
  final String region;
  final double low;
  final double average;
  final double high;
  final DateTime recordedAt;

  bool get isRecent => DateTime.now().difference(recordedAt).inDays <= 30;

  MarketPrice copyWith({
    String? id,
    String? productName,
    String? region,
    double? low,
    double? average,
    double? high,
    DateTime? recordedAt,
  }) {
    return MarketPrice(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      region: region ?? this.region,
      low: low ?? this.low,
      average: average ?? this.average,
      high: high ?? this.high,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'product_name': productName,
        'region': region,
        'low': low,
        'average': average,
        'high': high,
        'recorded_at': timestampToFirestore(recordedAt),
      };

  factory MarketPrice.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return MarketPrice.fromMap(data);
  }

  factory MarketPrice.fromMap(Map<String, Object?> map) {
    return MarketPrice(
      id: map['id']! as String,
      productName: (map['product_name'] ?? '') as String,
      region: (map['region'] ?? '') as String,
      low: doubleFromFirestore(map['low']),
      average: doubleFromFirestore(map['average']),
      high: doubleFromFirestore(map['high']),
      recordedAt: timestampFromFirestoreRequired(map['recorded_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarketPrice &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            productName == other.productName &&
            region == other.region &&
            low == other.low &&
            average == other.average &&
            high == other.high &&
            recordedAt == other.recordedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        productName,
        region,
        low,
        average,
        high,
        recordedAt,
      );
}

/// Backward-compatible alias for existing service contracts.
typedef PriceHistory = MarketPrice;
