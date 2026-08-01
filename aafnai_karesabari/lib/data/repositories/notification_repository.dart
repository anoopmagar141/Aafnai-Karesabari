import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_notification.dart';
import 'firestore_repository.dart';

abstract class NotificationStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}

class FlutterSecureNotificationStorage implements NotificationStorage {
  FlutterSecureNotificationStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) => _storage.write(key: key, value: value);
}

class NotificationListFilter {
  const NotificationListFilter({
    required this.userId,
    this.isRead,
    this.limit,
  });

  final String userId;
  final bool? isRead;
  final int? limit;
}

abstract class NotificationRepository {
  Future<AppNotification> create(AppNotification notification);
  Future<void> update(AppNotification notification);
  Future<void> delete(String notificationId);
  Future<AppNotification?> getById(String notificationId);
  Stream<AppNotification?> stream(String notificationId);
  Future<List<AppNotification>> list({required NotificationListFilter filter});
}

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _notifications = (firestore ?? FirebaseFirestore.instance)
            .collection('notifications');

  final CollectionReference<Map<String, dynamic>> _notifications;

  @override
  Future<AppNotification> create(AppNotification notification) =>
      runFirestore(() async {
        await _notifications.doc(notification.id).set(notification.toFirestore());
        return notification;
      }, message: 'Unable to create notification.');

  @override
  Future<void> update(AppNotification notification) => runFirestore(
        () => _notifications
            .doc(notification.id)
            .set(notification.toFirestore(), SetOptions(merge: true)),
        message: 'Unable to update notification.',
      );

  @override
  Future<void> delete(String notificationId) => runFirestore(
        () => _notifications.doc(notificationId).delete(),
        message: 'Unable to delete notification.',
      );

  @override
  Future<AppNotification?> getById(String notificationId) =>
      runFirestore(() async {
        final snapshot = await _notifications.doc(notificationId).get();
        if (!snapshot.exists) return null;
        return AppNotification.fromFirestore(snapshot);
      }, message: 'Unable to load notification.');

  @override
  Stream<AppNotification?> stream(String notificationId) {
    return mapDocumentStream(
      _notifications.doc(notificationId),
      AppNotification.fromFirestore,
    );
  }

  @override
  Future<List<AppNotification>> list({required NotificationListFilter filter}) =>
      runFirestore(() async {
        Query<Map<String, dynamic>> query = _notifications
            .where('user_id', isEqualTo: filter.userId)
            .orderBy('created_at', descending: true);

        final isRead = filter.isRead;
        if (isRead != null) {
          query = query.where('is_read', isEqualTo: isRead);
        }

        final limit = filter.limit;
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, AppNotification.fromFirestore);
      }, message: 'Unable to load notifications.');
}

class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository({NotificationStorage? storage})
      : _storage = storage ?? FlutterSecureNotificationStorage();

  static const _storageKey = 'hamro_karesabari_notifications';
  final NotificationStorage _storage;
  final Map<String, AppNotification> _notifications = {};
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final entry in decoded) {
          final notification = AppNotification.fromJson(
              Map<String, Object?>.from(entry as Map<String, dynamic>));
          _notifications[notification.id] = notification;
        }
      } catch (_) {
        _notifications.clear();
      }
    }
    _initialized = true;
  }

  Future<void> _saveCache() async {
    final encoded = jsonEncode(_notifications.values
        .map((notification) => notification.toJson())
        .toList(growable: false));
    await _storage.write(key: _storageKey, value: encoded);
  }

  @override
  Future<AppNotification> create(AppNotification notification) async {
    await _ensureInitialized();
    _notifications[notification.id] = notification;
    await _saveCache();
    return notification;
  }

  @override
  Future<void> update(AppNotification notification) async {
    await _ensureInitialized();
    _notifications[notification.id] = notification;
    await _saveCache();
  }

  @override
  Future<void> delete(String notificationId) async {
    await _ensureInitialized();
    _notifications.remove(notificationId);
    await _saveCache();
  }

  @override
  Future<AppNotification?> getById(String notificationId) async {
    await _ensureInitialized();
    return _notifications[notificationId];
  }

  @override
  Stream<AppNotification?> stream(String notificationId) async* {
    await _ensureInitialized();
    yield _notifications[notificationId];
  }

  @override
  Future<List<AppNotification>> list(
      {required NotificationListFilter filter}) async {
    await _ensureInitialized();
    var results = _notifications.values
        .where((notification) => notification.userId == filter.userId)
        .toList();
    final isRead = filter.isRead;
    if (isRead != null) {
      results =
          results.where((notification) => notification.isRead == isRead).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limit = filter.limit;
    if (limit != null) {
      return results.take(limit).toList(growable: false);
    }
    return results;
  }
}
