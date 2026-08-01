import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_karesabari/data/models/app_notification.dart';
import 'package:hamro_karesabari/data/models/app_user.dart';
import 'package:hamro_karesabari/data/models/listing.dart';
import 'package:hamro_karesabari/data/models/order.dart';
import 'package:hamro_karesabari/data/models/review.dart';
import 'package:hamro_karesabari/data/repositories/listing_repository.dart';
import 'package:hamro_karesabari/data/repositories/market_price_repository.dart';
import 'package:hamro_karesabari/data/repositories/notification_repository.dart';
import 'package:hamro_karesabari/data/repositories/order_repository.dart';
import 'package:hamro_karesabari/data/repositories/review_repository.dart';
import 'package:hamro_karesabari/data/repositories/user_repository.dart';

class FakeNotificationStorage implements NotificationStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final createdAt = DateTime(2026, 7, 28, 9, 0);

  group('LocalUserRepository', () {
    test('supports create, getById, update, delete, and list', () async {
      final repository = LocalUserRepository();
      final user = AppUser(
        id: 'user-1',
        role: UserRole.consumer,
        name: 'Sita',
        phone: '9800000000',
        language: AppLanguage.ne,
        email: 'sita@example.com',
        createdAt: createdAt,
      );

      await repository.create(user);
      expect(await repository.getById('user-1'), user);
      expect(await repository.read('user-1'), user);

      final updated = user.copyWith(name: 'Sita Thapa');
      await repository.update(updated);
      expect(await repository.getById('user-1'), updated);

      expect(await repository.list(), [updated]);

      await repository.delete('user-1');
      expect(await repository.getById('user-1'), isNull);
    });
  });

  group('LocalListingRepository', () {
    test('seeds listings and supports CRUD', () async {
      final repository = LocalListingRepository();
      final seeded = await repository.list();
      expect(seeded, isNotEmpty);

      final custom = Listing(
        id: 'custom-1',
        farmerId: 'farmer-1',
        productName: 'Carrots',
        category: ListingCategory.vegetable,
        pricePerUnit: 70,
        unit: ListingUnit.kg,
        stockQuantity: 10,
        status: ListingStatus.draft,
        createdAt: createdAt,
      );

      await repository.create(custom);
      expect(await repository.getById('custom-1'), custom);

      final farmerList = await repository.list(
        filter: const ListingListFilter(farmerId: 'farmer-1'),
      );
      expect(farmerList.any((listing) => listing.id == 'custom-1'), isTrue);

      await repository.delete('custom-1');
      expect(await repository.getById('custom-1'), isNull);
    });
  });

  group('LocalOrderRepository', () {
    test('supports create, list filters, and delete', () async {
      final repository = LocalOrderRepository();
      final order = Order(
        id: 'order-1',
        consumerId: 'consumer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        quantity: 2,
        totalPrice: 240,
        status: OrderStatus.pending,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      await repository.create(order);
      final farmerOrders = await repository.list(
        filter: const OrderListFilter(farmerId: 'farmer-1'),
      );
      expect(farmerOrders, [order]);

      await repository.delete('order-1');
      expect(await repository.getById('order-1'), isNull);
    });
  });

  group('LocalReviewRepository', () {
    test('supports create and list by farmer', () async {
      final repository = LocalReviewRepository();
      final review = Review(
        id: 'review-1',
        orderId: 'order-1',
        consumerId: 'consumer-1',
        farmerId: 'farmer-1',
        rating: 5,
        createdAt: createdAt,
      );

      await repository.create(review);
      final farmerReviews = await repository.list(
        filter: const ReviewListFilter(farmerId: 'farmer-1'),
      );
      expect(farmerReviews, [review]);
    });
  });

  group('LocalMarketPriceRepository', () {
    test('seeds market prices and supports filters', () async {
      final repository = LocalMarketPriceRepository();
      final kathmanduTomatoes = await repository.list(
        filter: const MarketPriceListFilter(
          productName: 'Tomatoes',
          region: 'Kathmandu',
        ),
      );
      expect(kathmanduTomatoes, isNotEmpty);
      expect(kathmanduTomatoes.first.productName, 'Tomatoes');
    });
  });

  group('LocalNotificationRepository', () {
    test('supports create, list, and update', () async {
      final repository = LocalNotificationRepository(
        storage: FakeNotificationStorage(),
      );
      final notification = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.orderNew,
        message: 'New order received',
        isRead: false,
        createdAt: createdAt,
      );

      await repository.create(notification);
      final unread = await repository.list(
        filter: const NotificationListFilter(userId: 'user-1', isRead: false),
      );
      expect(unread, [notification]);

      await repository.update(notification.copyWith(isRead: true));
      final stillUnread = await repository.list(
        filter: const NotificationListFilter(userId: 'user-1', isRead: false),
      );
      expect(stillUnread, isEmpty);
    });
  });
}
