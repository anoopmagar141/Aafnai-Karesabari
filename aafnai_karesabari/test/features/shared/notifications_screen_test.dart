import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aafnai_karesabari/data/models/app_notification.dart';
import 'package:aafnai_karesabari/data/models/order.dart';
import 'package:aafnai_karesabari/data/repositories/order_repository.dart';
import 'package:aafnai_karesabari/data/repositories/notification_repository.dart';
import 'package:aafnai_karesabari/data/services/notification_service.dart';
import 'package:aafnai_karesabari/features/shared/notifications/notifications_screen.dart';

class FakeNotificationService extends NotificationService {
  FakeNotificationService()
      : super(
          notificationRepository: FakeNotificationRepository(),
          localNotificationRepository: FakeNotificationRepository(),
        );
}

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
    return storage.values
        .where((notification) => notification.userId == filter.userId)
        .toList();
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
  @override
  Future<Order> create(Order order) async => order;
  @override
  Future<void> delete(String orderId) async {}
  @override
  Future<Order?> getById(String orderId) async => null;
  @override
  Future<List<Order>> list({OrderListFilter? filter}) async => [];
  @override
  Stream<Order?> stream(String orderId) async* {}
  @override
  Future<void> update(Order order) async {}
}

void main() {
  testWidgets('NotificationsScreen shows empty message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No notifications yet.'), findsOneWidget);
  });
}
