import 'package:flutter_test/flutter_test.dart';
import 'package:aafnai_karesabari/data/models/cart_entry.dart';
import 'package:aafnai_karesabari/data/models/listing.dart';
import 'package:aafnai_karesabari/data/repositories/cart_repository.dart';
import 'package:aafnai_karesabari/data/repositories/listing_repository.dart';
import 'package:aafnai_karesabari/data/services/cart_service.dart';

/// Reproduces the real SecureCartRepository behavior that caused
/// "Add to basket" to silently fail: returning an unmodifiable list when
/// the cart is empty (and a fixed-length one once it isn't).
class ImmutableListCartRepository implements CartRepository {
  List<CartEntry> _saved = const [];

  @override
  Future<List<CartEntry>> loadCart() async =>
      _saved.isEmpty ? const [] : List<CartEntry>.unmodifiable(_saved);

  @override
  Future<void> saveCart(List<CartEntry> entries) async {
    _saved = List<CartEntry>.from(entries);
  }

  @override
  Future<void> clearCart() async {
    _saved = const [];
  }
}

void main() {
  late ImmutableListCartRepository repository;
  late CartService cartService;

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
  );

  setUp(() {
    repository = ImmutableListCartRepository();
    cartService = CartService(
      repository: repository,
      listingRepository: LocalListingRepository(seed: {listing.id: listing}),
    );
  });

  test('adding the first item to an empty cart does not throw', () async {
    await cartService.addItem(listingId: listing.id);

    final cart = await cartService.loadCart();
    expect(cart, hasLength(1));
    expect(cart.first.listingId, listing.id);
  });

  test('adding a second, different item to a non-empty cart does not throw', () async {
    await cartService.addItem(listingId: listing.id);
    await cartService.addItem(listingId: 'listing-2');

    final cart = await cartService.loadCart();
    expect(cart, hasLength(2));
  });

  test('removing an item from a cart backed by an unmodifiable list does not throw', () async {
    await cartService.addItem(listingId: listing.id);
    await cartService.removeItem(listing.id);

    final cart = await cartService.loadCart();
    expect(cart, isEmpty);
  });
}
