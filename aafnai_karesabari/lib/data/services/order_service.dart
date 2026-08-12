import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../models/cart_entry.dart';
import '../models/listing.dart';
import '../models/order.dart';
import '../models/app_notification.dart';
import '../repositories/listing_repository.dart';
import '../repositories/order_repository.dart';
import '../services/notification_service.dart';
import 'commission_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService(notificationService: ref.read(notificationServiceProvider)));

class OrderService {
  OrderService({
    OrderRepository? orderRepository,
    OrderRepository? localOrderRepository,
    ListingRepository? listingRepository,
    ListingRepository? localListingRepository,
    CommissionService? commissionService,
    NotificationService? notificationService,
  })  : _orderRepository = orderRepository ?? FirestoreOrderRepository(),
        _localOrderRepository = localOrderRepository ?? LocalOrderRepository(),
        _listingRepository = listingRepository ?? FirestoreListingRepository(),
        _localListingRepository = localListingRepository ?? LocalListingRepository(),
        _commissionService = commissionService ?? LocalCommissionService(),
        _notificationService = notificationService ?? NotificationService();

  final OrderRepository _orderRepository;
  final OrderRepository _localOrderRepository;
  final ListingRepository _listingRepository;
  final ListingRepository _localListingRepository;
  final CommissionService _commissionService;
  final NotificationService _notificationService;

  Future<List<Order>> listConsumerOrders(String consumerId) => _runOrder(
        (repository) => repository.list(
          filter: OrderListFilter(consumerId: consumerId),
        ),
      );

  Future<List<Order>> listFarmerOrders(String farmerId) => _runOrder(
        (repository) => repository.list(
          filter: OrderListFilter(farmerId: farmerId),
        ),
      );

  Future<Order?> getOrderById(String orderId) => _runOrder(
        (repository) => repository.getById(orderId),
      );

  /// Unfiltered listing across every buyer/seller, for admin oversight.
  Future<List<Order>> listAllOrders({int limit = 200}) => _runOrder(
        (repository) => repository.list(filter: OrderListFilter(limit: limit)),
      );

  Future<Order> createOrder({
    required String consumerId,
    required Listing listing,
    required int quantity,
    double? offeredPricePerUnit,
  }) async {
    final now = DateTime.now();

    // A buyer's offer can never go below the seller's stated minimum,
    // regardless of what the client sent — fall back to the listed price
    // for anything invalid rather than silently honoring a bad offer.
    final pricePerUnit = (offeredPricePerUnit != null &&
            offeredPricePerUnit > 0 &&
            offeredPricePerUnit <= listing.pricePerUnit &&
            (listing.minBargainPrice == null ||
                offeredPricePerUnit >= listing.minBargainPrice!))
        ? offeredPricePerUnit
        : listing.pricePerUnit;

    final totalPrice = pricePerUnit * quantity;
    final commission = _commissionService.calculateCommission(totalPrice);
    final payout = _commissionService.calculatePayout(totalPrice);

    final order = Order(
      id: _generateOrderId(),
      consumerId: consumerId,
      farmerId: listing.farmerId,
      listingId: listing.id,
      quantity: quantity.toDouble(),
      totalPrice: totalPrice,
      commissionAmount: commission,
      farmerPayout: payout,
      status: OrderStatus.pending,
      createdAt: now,
      updatedAt: now,
      listingPricePerUnit: listing.pricePerUnit,
    );

    final createdOrder = await _runOrder((repository) => repository.create(order));
    await _notifyOrderCreated(createdOrder, listing);
    return createdOrder;
  }

  Future<List<Order>> createOrdersForCart(
    String consumerId,
    List<CartEntry> entries,
  ) async {
    final orders = <Order>[];
    for (var entry in entries) {
      final listing = await _runListing((repository) => repository.getById(entry.listingId));
      if (listing == null) {
        continue;
      }
      final order = await createOrder(
        consumerId: consumerId,
        listing: listing,
        quantity: entry.quantity,
        offeredPricePerUnit: entry.offeredPricePerUnit,
      );
      orders.add(order);
    }
    return orders;
  }

  Future<Order> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final order = await getOrderById(orderId);
    if (order == null) {
      throw const AppException('Order not found.');
    }
    final updated = order.copyWith(status: status, updatedAt: DateTime.now());
    await _runOrder((repository) => repository.update(updated));
    await _notifyOrderStatusUpdated(updated);
    return updated;
  }

  Future<void> _notifyOrderCreated(Order order, Listing listing) async {
    await _notificationService.createNotification(
      userId: order.consumerId,
      type: NotificationType.orderNew,
      message: order.isNegotiated
          ? 'Your offer of NPR ${order.pricePerUnit.toStringAsFixed(0)}/${listing.unit.name} for ${listing.productName} has been sent to the seller.'
          : 'Your order for ${listing.productName} has been placed.',
    );
    await _notificationService.createNotification(
      userId: order.farmerId,
      type: NotificationType.orderNew,
      message: order.isNegotiated
          ? 'New offer for ${listing.productName}: buyer proposed NPR ${order.pricePerUnit.toStringAsFixed(0)}/${listing.unit.name} (listed at NPR ${listing.pricePerUnit.toStringAsFixed(0)}). Review and accept if the price works for you.'
          : 'New order received for ${listing.productName}.',
    );
  }

  Future<void> _notifyOrderStatusUpdated(Order order) async {
    if (order.status == OrderStatus.accepted) {
      await _notificationService.createNotification(
        userId: order.consumerId,
        type: NotificationType.orderAccepted,
        message: 'Good news — your order is on the way!',
      );
    } else if (order.status == OrderStatus.completed) {
      await _notificationService.createNotification(
        userId: order.consumerId,
        type: NotificationType.orderDelivered,
        message: 'Your order ${order.id} has been delivered.',
      );
    } else if (order.status == OrderStatus.rejected) {
      await _notificationService.createNotification(
        userId: order.consumerId,
        type: NotificationType.orderNew,
        message: order.isNegotiated
            ? 'The seller declined your offer for this order.'
            : 'Your order ${order.id} was declined by the seller.',
      );
    } else if (order.status == OrderStatus.cancelled) {
      await _notificationService.createNotification(
        userId: order.consumerId,
        type: NotificationType.orderNew,
        message: 'Your order ${order.id} was cancelled.',
      );
    }
  }

  Future<T> _runOrder<T>(Future<T> Function(OrderRepository repository) action) async {
    try {
      return await action(_orderRepository);
    } on AppException {
      return await action(_localOrderRepository);
    }
  }

  Future<T> _runListing<T>(Future<T> Function(ListingRepository repository) action) async {
    try {
      return await action(_listingRepository);
    } on AppException {
      return await action(_localListingRepository);
    }
  }

  String _generateOrderId() =>
      'order-${DateTime.now().millisecondsSinceEpoch}';
}
