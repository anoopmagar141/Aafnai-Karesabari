import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

enum NotificationType {
  orderNew,
  orderAccepted,
  promoExpiring,
  paymentReceived,
  orderDelivered,
}

/// An in-app notification for one user (new order, order accepted, etc.),
/// shown on [NotificationsScreen] and counted for the unread bell badge.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'message': message,
        'is_read': isRead,
        'created_at': timestampToFirestore(createdAt),
      };

  Map<String, Object?> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'message': message,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, Object?> map) {
    return AppNotification(
      id: map['id']! as String,
      userId: (map['user_id'] ?? '') as String,
      type: NotificationType.values.byName(map['type']! as String),
      message: (map['message'] ?? '') as String,
      isRead: (map['is_read'] ?? false) as bool,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return AppNotification.fromMap(data);
  }

  factory AppNotification.fromMap(Map<String, Object?> map) {
    return AppNotification(
      id: map['id']! as String,
      userId: (map['user_id'] ?? '') as String,
      type: NotificationType.values.byName(map['type']! as String),
      message: (map['message'] ?? '') as String,
      isRead: (map['is_read'] ?? false) as bool,
      createdAt: timestampFromFirestoreRequired(map['created_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppNotification &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            userId == other.userId &&
            type == other.type &&
            message == other.message &&
            isRead == other.isRead &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        type,
        message,
        isRead,
        createdAt,
      );
}
