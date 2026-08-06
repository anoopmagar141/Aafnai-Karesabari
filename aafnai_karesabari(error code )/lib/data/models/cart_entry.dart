import 'dart:convert';

class CartEntry {
  const CartEntry({required this.listingId, required this.quantity});

  final String listingId;
  final int quantity;

  CartEntry copyWith({String? listingId, int? quantity}) {
    return CartEntry(
      listingId: listingId ?? this.listingId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, Object?> toJson() => {
        'listing_id': listingId,
        'quantity': quantity,
      };

  factory CartEntry.fromJson(Map<String, Object?> json) {
    return CartEntry(
      listingId: json['listing_id'] as String,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 0,
    );
  }

  static List<CartEntry> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => CartEntry.fromJson(Map<String, Object?>.from(item)))
        .toList(growable: false);
  }

  static String listToJson(List<CartEntry> entries) {
    return jsonEncode(entries.map((entry) => entry.toJson()).toList());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CartEntry &&
            runtimeType == other.runtimeType &&
            listingId == other.listingId &&
            quantity == other.quantity;
  }

  @override
  int get hashCode => Object.hash(listingId, quantity);
}
