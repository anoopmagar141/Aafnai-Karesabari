import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_karesabari/data/models/app_notification.dart';
import 'package:hamro_karesabari/data/models/app_user.dart';
import 'package:hamro_karesabari/data/models/listing.dart';
import 'package:hamro_karesabari/data/models/market_price.dart';
import 'package:hamro_karesabari/data/models/order.dart';
import 'package:hamro_karesabari/data/models/review.dart';

void main() {
  final createdAt = DateTime(2026, 7, 1, 10, 30);
  final updatedAt = DateTime(2026, 7, 2, 12, 0);

  group('AppUser', () {
    test('serializes and deserializes with Firestore timestamps', () {
      final user = AppUser(
        id: 'user-1',
        role: UserRole.consumer,
        name: 'Sita',
        phone: '9800000000',
        language: AppLanguage.ne,
        email: 'sita@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        location: 'Lalitpur',
        createdAt: createdAt,
        profileCompleted: true,
      );

      final map = user.toFirestore();
      expect(map['role'], 'consumer');
      expect(map['created_at'], isA<Timestamp>());

      final restored = AppUser.fromMap(
        Map<String, Object?>.from(map)..['created_at'] = createdAt,
      );
      expect(restored, user);
    });

    test('copyWith and equality work', () {
      final user = AppUser(
        id: 'user-1',
        role: UserRole.farmer,
        name: 'Hari',
        phone: '9800000001',
        language: AppLanguage.en,
        email: 'hari@example.com',
        createdAt: createdAt,
      );
      final updated = user.copyWith(name: 'Hari Thapa');
      expect(updated.name, 'Hari Thapa');
      expect(updated, isNot(user));
    });
  });

  group('Listing', () {
    test('round-trips through map serialization', () {
      final listing = Listing(
        id: 'listing-1',
        farmerId: 'farmer-1',
        productName: 'Fresh Tomatoes',
        description: 'Locally grown',
        category: ListingCategory.vegetable,
        pricePerUnit: 120,
        unit: ListingUnit.kg,
        stockQuantity: 12,
        location: 'Bhaktapur',
        photoUrls: const ['https://example.com/tomato.jpg'],
        status: ListingStatus.active,
        isFeatured: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = Listing.fromMap(listing.toFirestore());
      expect(restored, listing.copyWith(displayIcon: restored.displayIcon));
      expect(restored.title, 'Fresh Tomatoes');
    });
  });

  group('Order', () {
    test('round-trips through map serialization', () {
      final order = Order(
        id: 'order-1',
        consumerId: 'consumer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        quantity: 2,
        totalPrice: 240,
        commissionAmount: 24,
        farmerPayout: 216,
        status: OrderStatus.pending,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = Order.fromMap(order.toFirestore());
      expect(restored, order);
      expect(restored.canBeCancelled, isTrue);
      expect(restored.canBeReviewed, isFalse);
    });
  });

  group('Review', () {
    test('round-trips through map serialization', () {
      final review = Review(
        id: 'review-1',
        orderId: 'order-1',
        consumerId: 'consumer-1',
        farmerId: 'farmer-1',
        rating: 5,
        comment: 'Great quality',
        createdAt: createdAt,
      );

      final restored = Review.fromMap(review.toFirestore());
      expect(restored, review);
    });
  });

  group('MarketPrice', () {
    test('round-trips through map serialization', () {
      final price = MarketPrice(
        id: 'price-1',
        productName: 'Tomatoes',
        region: 'Kathmandu',
        low: 90,
        average: 120,
        high: 150,
        recordedAt: createdAt,
      );

      final restored = MarketPrice.fromMap(price.toFirestore());
      expect(restored, price);
      expect(restored.isRecent, isFalse);
    });

    test('PriceHistory typedef resolves to MarketPrice', () {
      final price = PriceHistory(
        id: 'price-1',
        productName: 'Tomatoes',
        region: 'Kathmandu',
        low: 90,
        average: 120,
        high: 150,
        recordedAt: createdAt,
      );
      expect(price, isA<MarketPrice>());
    });
  });

  group('AppNotification', () {
    test('round-trips through map serialization', () {
      final notification = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.orderNew,
        message: 'You have a new order',
        isRead: false,
        createdAt: createdAt,
      );

      final restored = AppNotification.fromMap(notification.toFirestore());
      expect(restored, notification);
    });
  });
}
