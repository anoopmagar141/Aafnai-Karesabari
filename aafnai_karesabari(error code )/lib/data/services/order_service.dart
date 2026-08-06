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

  Future<Order> createOrder({
    required String consumerId,
    required Listing listing,
    required int quantity,
  }) async {
    final now = DateTime.now();
    final totalPrice = listing.pricePerUnit * quantity;
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
      message: 'Your order for ${listing.productName} has been placed.',
    );
    await _notificationService.createNotification(
      userId: order.farmerId,
      type: NotificationType.orderNew,
      message: 'New order received for ${listing.productName}.',
    );
  }

  Future<void> _notifyOrderStatusUpdated(Order order) async {
    if (order.status == OrderStatus.accepted) {
      await _notificationService.createNotification(
        userId: order.consumerId,
        type: NotificationType.orderAccepted,
        message: 'Your order ${order.id} has been accepted.',
      );
    } else if (order.status == OrderStatus.completed) {
      await _notificationService.createNotification(
        userId: order.consumerId,
        type: NotificationType.orderDelivered,
        message: 'Your order ${order.id} has been delivered.',
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
