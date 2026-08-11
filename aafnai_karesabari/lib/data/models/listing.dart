import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/utils/listing_icons.dart';
import 'firestore_helpers.dart';

enum ListingCategory { vegetable, fruit, grain }

enum ListingUnit { kg, piece }

enum ListingStatus { active, soldOut, draft }

class Listing {
  const Listing({
    required this.id,
    required this.farmerId,
    required this.productName,
    required this.category,
    required this.pricePerUnit,
    required this.unit,
    required this.stockQuantity,
    required this.status,
    required this.createdAt,
    this.description,
    this.location,
    this.updatedAt,
    this.photoUrls = const [],
    this.isFeatured = false,
    this.featuredExpiry,
    this.displayIcon = Icons.local_florist,
    this.minBargainPrice,
  });

  final String id;
  final String farmerId;
  final String productName;
  final String? description;
  final ListingCategory category;
  final double pricePerUnit;
  final ListingUnit unit;
  final int stockQuantity;
  final String? location;
  final List<String> photoUrls;
  final ListingStatus status;
  final bool isFeatured;
  final DateTime? featuredExpiry;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Prototype-only fallback when no Storage image exists yet.
  final IconData displayIcon;

  /// Lowest price per unit the seller will accept from a buyer's offer.
  /// Null means the seller isn't accepting negotiated offers on this listing.
  final double? minBargainPrice;

  bool get acceptsBargaining => minBargainPrice != null;

  String get title => productName;

  Listing copyWith({
    String? id,
    String? farmerId,
    String? productName,
    String? description,
    ListingCategory? category,
    double? pricePerUnit,
    ListingUnit? unit,
    int? stockQuantity,
    String? location,
    List<String>? photoUrls,
    ListingStatus? status,
    bool? isFeatured,
    DateTime? featuredExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    IconData? displayIcon,
    double? minBargainPrice,
    bool clearMinBargainPrice = false,
  }) {
    return Listing(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      category: category ?? this.category,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredExpiry: featuredExpiry ?? this.featuredExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayIcon: displayIcon ?? this.displayIcon,
      minBargainPrice: clearMinBargainPrice
          ? null
          : (minBargainPrice ?? this.minBargainPrice),
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'farmer_id': farmerId,
        'product_name': productName,
        'title': productName,
        'description': description,
        'category': category.name,
        'price_per_unit': pricePerUnit,
        'unit': unit.name,
        'stock_quantity': stockQuantity,
        'location': location,
        'photo_urls': photoUrls,
        'status': status.name,
        'is_featured': isFeatured,
        'featured_expiry': timestampToFirestoreNullable(featuredExpiry),
        'created_at': timestampToFirestore(createdAt),
        'updated_at': timestampToFirestoreNullable(updatedAt ?? createdAt),
        'min_bargain_price': minBargainPrice,
      };

  factory Listing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return Listing.fromMap(data);
  }

  factory Listing.fromMap(Map<String, Object?> map) {
    final productName = (map['product_name'] ?? map['title'] ?? '') as String;
    final category = ListingCategory.values.byName(map['category']! as String);
    return Listing(
      id: map['id']! as String,
      farmerId: (map['farmer_id'] ?? '') as String,
      productName: productName,
      description: map['description'] as String?,
      category: category,
      pricePerUnit: doubleFromFirestore(map['price_per_unit']),
      unit: ListingUnit.values.byName(map['unit']! as String),
      stockQuantity: intFromFirestore(map['stock_quantity']),
      location: map['location'] as String?,
      photoUrls: stringListFromFirestore(map['photo_urls']),
      status: ListingStatus.values.byName(map['status']! as String),
      isFeatured: (map['is_featured'] ?? false) as bool,
      featuredExpiry: timestampFromFirestore(map['featured_expiry']),
      createdAt: timestampFromFirestoreRequired(map['created_at']),
      updatedAt: timestampFromFirestore(map['updated_at']),
      displayIcon: iconForListing(productName, category),
      minBargainPrice: map['min_bargain_price'] == null
          ? null
          : doubleFromFirestore(map['min_bargain_price']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Listing &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            farmerId == other.farmerId &&
            productName == other.productName &&
            description == other.description &&
            category == other.category &&
            pricePerUnit == other.pricePerUnit &&
            unit == other.unit &&
            stockQuantity == other.stockQuantity &&
            location == other.location &&
            _listEquals(photoUrls, other.photoUrls) &&
            status == other.status &&
            isFeatured == other.isFeatured &&
            featuredExpiry == other.featuredExpiry &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            minBargainPrice == other.minBargainPrice;
  }

  @override
  int get hashCode => Object.hash(
        id,
        farmerId,
        productName,
        description,
        category,
        pricePerUnit,
        unit,
        stockQuantity,
        location,
        Object.hashAll(photoUrls),
        status,
        isFeatured,
        featuredExpiry,
        createdAt,
        updatedAt,
        minBargainPrice,
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
