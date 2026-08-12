import 'package:flutter_test/flutter_test.dart';
import 'package:aafnai_karesabari/data/models/app_notification.dart';
import 'package:aafnai_karesabari/data/models/order.dart';
import 'package:aafnai_karesabari/data/repositories/order_repository.dart';
import 'package:aafnai_karesabari/data/repositories/notification_repository.dart';
import 'package:aafnai_karesabari/data/services/notification_service.dart';

class FakeNotificationRepository implements NotificationRepository {
  final Map<String, AppNotification> storage = {};

  @override
  Future<AppNotification> create(AppNotification notification) async {
    storage[notification.id] = notification;
    return notification;
  }

  @override
  Future<void> delete(String notificationId) async {
    storage.remove(notificationId);
  }

  @override
  Future<AppNotification?> getById(String notificationId) async {
    return storage[notificationId];
  }

  @override
  Future<List<AppNotification>> list({required NotificationListFilter filter}) async {
    var results = storage.values
        .where((notification) => notification.userId == filter.userId)
        .toList();
    if (filter.isRead != null) {
      results = results.where((notification) => notification.isRead == filter.isRead).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (filter.limit != null) {
      return results.take(filter.limit!).toList();
    }
    return results;
  }

  @override
  Stream<AppNotification?> stream(String notificationId) async* {
    yield storage[notificationId];
  }

  @override
  Future<void> update(AppNotification notification) async {
    storage[notification.id] = notification;
  }

  @override
  Stream<int> streamUnreadCount(String userId) async* {
    yield storage.values.where((n) => n.userId == userId && !n.isRead).length;
  }
}

class FakeOrderRepository implements OrderRepository {
  final Map<String, Order> storage = {};

  @override
  Future<Order> create(Order order) async {
    storage[order.id] = order;
    return order;
  }

  @override
  Future<void> delete(String orderId) async {
    storage.remove(orderId);
  }

  @override
  Future<Order?> getById(String orderId) async {
    return storage[orderId];
  }

  @override
  Future<List<Order>> list({OrderListFilter? filter}) async {
    return storage.values.toList();
  }

  @override
  Stream<Order?> stream(String orderId) async* {
    yield storage[orderId];
  }

  @override
  Future<void> update(Order order) async {
    storage[order.id] = order;
  }
}

void main() {
  late FakeNotificationRepository notificationRepository;
  late NotificationService notificationService;

  setUp(() {
    notificationRepository = FakeNotificationRepository();
    notificationService = NotificationService(
      notificationRepository: notificationRepository,
      localNotificationRepository: notificationRepository,
    );
  });

  test('creates and lists notifications', () async {
    await notificationService.createNotification(
      userId: 'user-1',
      type: NotificationType.orderNew,
      message: 'New order',
    );

    final notifications = await notificationService.listNotifications(userId: 'user-1');
    expect(notifications, isNotEmpty);
    expect(notifications.first.message, 'New order');
  });

  test('marks notification as read', () async {
    final notification = await notificationService.createNotification(
      userId: 'user-2',
      type: NotificationType.orderAccepted,
      message: 'Order accepted',
    );

    await notificationService.markAsRead(notification.id);
    final updated = await notificationService.getNotificationById(notification.id);
    expect(updated?.isRead, isTrue);
  });
}
