enum NotificationType { orderNew, orderAccepted, promoExpiring, paymentReceived, orderDelivered }
class AppNotification { const AppNotification({required this.id, required this.userId, required this.type, required this.message, required this.isRead, required this.createdAt}); final String id, userId, message; final NotificationType type; final bool isRead; final DateTime createdAt; }
