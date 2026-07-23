enum OrderStatus { pending, accepted, rejected, cancelled, completed }

class Order {
  const Order({required this.id, required this.consumerId, required this.farmerId, required this.listingId, required this.quantity, required this.totalPrice, required this.status, required this.createdAt, required this.updatedAt, this.commissionAmount, this.farmerPayout});
  final String id, consumerId, farmerId, listingId;
  final double quantity, totalPrice;
  /// These are server-generated display values; client code must not calculate or persist them.
  final double? commissionAmount, farmerPayout;
  final OrderStatus status;
  final DateTime createdAt, updatedAt;
  bool get canBeCancelled => status == OrderStatus.pending;
  bool get canBeReviewed => status == OrderStatus.completed;
}
