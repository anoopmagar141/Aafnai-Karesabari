import 'package:flutter_test/flutter_test.dart';
import 'package:aafnai_karesabari/data/models/app_notification.dart';
import 'package:aafnai_karesabari/data/models/listing.dart';
import 'package:aafnai_karesabari/data/models/order.dart';
import 'package:aafnai_karesabari/data/repositories/order_repository.dart';
import 'package:aafnai_karesabari/data/repositories/notification_repository.dart';
import 'package:aafnai_karesabari/data/repositories/listing_repository.dart';
import 'package:aafnai_karesabari/data/services/commission_service.dart';
import 'package:aafnai_karesabari/data/services/notification_service.dart';
import 'package:aafnai_karesabari/data/services/order_service.dart';

class FakeOrderRepository implements OrderRepository {
  final Map<String, Order> storage = {};

  @override
  Future<Order> create(Order order) async {
    storage[order.id] = order;
    return order;
  }

  @override
  Future<void> delete(String orderId) async => storage.remove(orderId);

  @override
  Future<Order?> getById(String orderId) async => storage[orderId];

  @override
  Future<List<Order>> list({OrderListFilter? filter}) async => storage.values.toList();

  @override
  Stream<Order?> stream(String orderId) async* {
    yield storage[orderId];
  }

  @override
  Future<void> update(Order order) async => storage[order.id] = order;
}

class FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> sent = [];

  @override
  Future<AppNotification> create(AppNotification notification) async {
    sent.add(notification);
    return notification;
  }

  @override
  Future<void> delete(String notificationId) async {}

  @override
  Future<AppNotification?> getById(String notificationId) async {
    for (final notification in sent) {
      if (notification.id == notificationId) return notification;
    }
    return null;
  }

  @override
  Future<List<AppNotification>> list({required NotificationListFilter filter}) async {
    return sent.where((n) => n.userId == filter.userId).toList();
  }

  @override
  Stream<AppNotification?> stream(String notificationId) async* {}

  @override
  Future<void> update(AppNotification notification) async {
    final index = sent.indexWhere((n) => n.id == notification.id);
    if (index != -1) sent[index] = notification;
  }
}

void main() {
  late FakeOrderRepository orderRepository;
  late FakeNotificationRepository notificationRepository;
  late OrderService orderService;

  final listing = Listing(
    id: 'listing-1',
    farmerId: 'farmer-1',
    productName: 'Tomatoes',
    category: ListingCategory.vegetable,
    pricePerUnit: 100,
    unit: ListingUnit.kg,
    stockQuantity: 50,
    status: ListingStatus.active,
    createdAt: DateTime(2026, 1, 1),
    minBargainPrice: 70,
  );

  setUp(() {
    orderRepository = FakeOrderRepository();
    notificationRepository = FakeNotificationRepository();
    orderService = OrderService(
      orderRepository: orderRepository,
      localOrderRepository: orderRepository,
      listingRepository: LocalListingRepository(seed: {listing.id: listing}),
      localListingRepository: LocalListingRepository(seed: {listing.id: listing}),
      commissionService: LocalCommissionService(),
      notificationService: NotificationService(
        notificationRepository: notificationRepository,
        localNotificationRepository: notificationRepository,
      ),
    );
  });

  group('bargaining', () {
    test('an order with no offer uses the listed price', () async {
      final order = await orderService.createOrder(
        consumerId: 'buyer-1',
        listing: listing,
        quantity: 2,
      );

      expect(order.pricePerUnit, 100);
      expect(order.totalPrice, 200);
      expect(order.isNegotiated, isFalse);
    });

    test('a valid offer at or above the minimum is honored', () async {
      final order = await orderService.createOrder(
        consumerId: 'buyer-1',
        listing: listing,
        quantity: 2,
        offeredPricePerUnit: 80,
      );

      expect(order.pricePerUnit, 80);
      expect(order.totalPrice, 160);
      expect(order.isNegotiated, isTrue);
      expect(order.listingPricePerUnit, 100);
    });

    test('an offer below the seller\'s minimum is rejected server-side and falls back to the listed price', () async {
      final order = await orderService.createOrder(
        consumerId: 'buyer-1',
        listing: listing,
        quantity: 2,
        offeredPricePerUnit: 50, // below minBargainPrice of 70
      );

      expect(order.pricePerUnit, 100);
      expect(order.isNegotiated, isFalse);
    });

    test('an offer above the listed price is rejected and falls back to the listed price', () async {
      final order = await orderService.createOrder(
        consumerId: 'buyer-1',
        listing: listing,
        quantity: 1,
        offeredPricePerUnit: 150,
      );

      expect(order.pricePerUnit, 100);
    });
  });

  group('status notifications', () {
    test('accepting an order tells the buyer it is on the way', () async {
      final order = await orderService.createOrder(
        consumerId: 'buyer-1',
        listing: listing,
        quantity: 1,
      );

      await orderService.updateOrderStatus(order.id, OrderStatus.accepted);

      final buyerNotifications = notificationRepository.sent
          .where((n) => n.userId == 'buyer-1' && n.type == NotificationType.orderAccepted);
      expect(buyerNotifications, isNotEmpty);
      expect(buyerNotifications.first.message, contains('on the way'));
    });
  });
}
