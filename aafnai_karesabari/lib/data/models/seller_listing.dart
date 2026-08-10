import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/firestore_helpers.dart';

class SellerListing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String productName;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final String unit;
  final List<String> imageUrls;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SellerListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.productName,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.imageUrls,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  SellerListing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? productName,
    String? description,
    String? category,
    double? price,
    int? quantity,
    String? unit,
    List<String>? imageUrls,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'productName': productName,
        'description': description,
        'category': category,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'imageUrls': imageUrls,
        'isPublished': isPublished,
        'createdAt': timestampToFirestore(createdAt),
        'updatedAt': timestampToFirestore(updatedAt),
      };

  factory SellerListing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return SellerListing.fromMap(data);
  }

  factory SellerListing.fromMap(Map<String, Object?> map) {
    return SellerListing(
      id: map['id']! as String,
      sellerId: map['sellerId'] as String,
      sellerName: map['sellerName'] as String,
      productName: map['productName'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      unit: map['unit'] as String,
      imageUrls: (map['imageUrls'] as List).cast<String>(),
      isPublished: map['isPublished'] as bool,
      createdAt: timestampFromFirestoreRequired(map['createdAt']),
      updatedAt: timestampFromFirestoreRequired(map['updatedAt']),
    );
  }
}
