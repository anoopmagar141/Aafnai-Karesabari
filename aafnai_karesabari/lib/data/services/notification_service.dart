import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Live unread-notification count for the signed-in user, for badges.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);
  return ref.watch(notificationServiceProvider).streamUnreadCount(uid);
});

/// Creates/lists/marks-read in-app notifications, and streams the
/// unread count for the notification bell badge. Falls back to a local
/// cache if Firestore fails, logging the real error so that fallback
/// doesn't silently hide a genuine bug (e.g. a missing index).
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

  Stream<int> streamUnreadCount(String userId) {
    try {
      return _notificationRepository.streamUnreadCount(userId);
    } catch (_) {
      return _localNotificationRepository.streamUnreadCount(userId);
    }
  }

  Future<T> _runNotification<T>(Future<T> Function(NotificationRepository repository) action) async {
    try {
      return await action(_notificationRepository);
    } on Exception catch (error, stack) {
      // Falling back to the (empty) local cache is intentional resilience
      // when Firestore is genuinely unreachable, but it also silently
      // hides real bugs (missing index, bad security rule) behind an
      // innocent-looking empty list. Log the real cause so it's visible
      // in the dev console instead of only ever seeing "no notifications".
      debugPrint('NotificationService: Firestore call failed, falling back to local cache: $error\n$stack');
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
