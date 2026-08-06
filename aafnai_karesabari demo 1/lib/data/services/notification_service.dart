import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  NotificationService({
    NotificationRepository? notificationRepository,
    NotificationRepository? localNotificationRepository,
  })  : _notificationRepository = notificationRepository ?? FirestoreNotificationRepository(),
        _localNotificationRepository = localNotificationRepository ?? LocalNotificationRepository();

  final NotificationRepository _notificationRepository;
  final NotificationRepository _localNotificationRepository;

  Future<AppNotification> createNotification({
    required String userId,
    required NotificationType type,
    required String message,
  }) async {
    final notification = AppNotification(
      id: 'notification-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
    );
    return _runNotification((repository) => repository.create(notification));
  }

  Future<List<AppNotification>> listNotifications({
    required String userId,
    bool? isRead,
    int? limit,
  }) async {
    return _runNotification((repository) => repository.list(
          filter: NotificationListFilter(
            userId: userId,
            isRead: isRead,
            limit: limit,
          ),
        ));
  }

  Future<void> markAsRead(String notificationId) async {
    final notification = await getNotificationById(notificationId);
    if (notification == null) return;
    final updated = notification.copyWith(isRead: true);
    await _runNotification((repository) => repository.update(updated));
  }

  Future<AppNotification?> getNotificationById(String notificationId) async {
    return _runNotification((repository) => repository.getById(notificationId));
  }

  Future<T> _runNotification<T>(Future<T> Function(NotificationRepository repository) action) async {
    try {
      return await action(_notificationRepository);
    } on Exception {
      return await action(_localNotificationRepository);
    }
  }

  Future<void> registerFirebaseListeners() async {
    if (kIsWeb) {
      debugPrint('Skipping FirebaseMessaging registration on web; web service worker support may not be configured.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      FirebaseMessaging.onMessage.listen((message) async {
        if (message.notification != null && message.data['user_id'] != null) {
          await createNotification(
            userId: message.data['user_id'] as String,
            type: NotificationType.values.firstWhere(
              (type) => type.name == message.data['type'],
              orElse: () => NotificationType.orderNew,
            ),
            message: message.notification?.body ?? message.notification?.title ?? 'You have a new update.',
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        // Attach any deep link handling or analytics if needed.
      });
    } catch (error, stack) {
      debugPrint('Failed to register Firebase listeners: $error\n$stack');
    }
  }
}
