import 'dart:convert';

class CartEntry {
  const CartEntry({
    required this.listingId,
    required this.quantity,
    this.offeredPricePerUnit,
  });

  final String listingId;
  final int quantity;

  /// The buyer's negotiated price per unit, if they made an offer instead
  /// of paying the listed price. Null means pay the listing's normal price.
  final double? offeredPricePerUnit;

  CartEntry copyWith({
    String? listingId,
    int? quantity,
    double? offeredPricePerUnit,
    bool clearOfferedPrice = false,
  }) {
    return CartEntry(
      listingId: listingId ?? this.listingId,
      quantity: quantity ?? this.quantity,
      offeredPricePerUnit: clearOfferedPrice
          ? null
          : (offeredPricePerUnit ?? this.offeredPricePerUnit),
    );
  }

  Map<String, Object?> toJson() => {
        'listing_id': listingId,
        'quantity': quantity,
        'offered_price_per_unit': offeredPricePerUnit,
      };

  factory CartEntry.fromJson(Map<String, Object?> json) {
    return CartEntry(
      listingId: json['listing_id'] as String,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 0,
      offeredPricePerUnit: json['offered_price_per_unit'] == null
          ? null
          : double.tryParse('${json['offered_price_per_unit']}'),
    );
  }

  static List<CartEntry> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => CartEntry.fromJson(Map<String, Object?>.from(item)))
        .toList();
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
            quantity == other.quantity &&
            offeredPricePerUnit == other.offeredPricePerUnit;
  }

  @override
  int get hashCode => Object.hash(listingId, quantity, offeredPricePerUnit);
}
