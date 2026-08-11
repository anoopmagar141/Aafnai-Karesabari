import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_entry.dart';
import '../models/listing.dart';
import '../repositories/cart_repository.dart';
import '../repositories/listing_repository.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());
final cartCountProvider = AsyncNotifierProvider<CartCountNotifier, int>(
  () => CartCountNotifier(),
);

class CartCountNotifier extends AsyncNotifier<int> {
  late final CartService _cartService;

  @override
  Future<int> build() async {
    _cartService = ref.read(cartServiceProvider);
    return _loadCount();
  }

  Future<int> _loadCount() async {
    final items = await _cartService.loadCart();
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<void> refreshCartCount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCount());
  }
}

class CartItemSummary {
  CartItemSummary({required this.entry, required this.listing});

  final CartEntry entry;
  final Listing listing;
}

class CartService {
  CartService({CartRepository? repository, ListingRepository? listingRepository})
      : _repository = repository ?? ResilientCartRepository(),
        _listingRepository = listingRepository ?? FirestoreListingRepository();

  final CartRepository _repository;
  final ListingRepository _listingRepository;

  Future<List<CartEntry>> loadCart() => _repository.loadCart();

  Future<void> clearCart() async {
    await _repository.clearCart();
  }

  Future<void> addItem({
    required String listingId,
    int quantity = 1,
    double? offeredPricePerUnit,
  }) async {
    // Defensive copy: some CartRepository implementations return a fixed-
    // length list (e.g. an empty `const []`), which would throw on .add().
    final entries = List<CartEntry>.of(await _repository.loadCart());
    final index = entries.indexWhere((entry) => entry.listingId == listingId);
    if (index == -1) {
      entries.add(CartEntry(
        listingId: listingId,
        quantity: quantity,
        offeredPricePerUnit: offeredPricePerUnit,
      ));
    } else {
      final existing = entries[index];
      entries[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
        offeredPricePerUnit: offeredPricePerUnit,
        clearOfferedPrice: offeredPricePerUnit == null,
      );
    }
    await _repository.saveCart(entries);
  }

  Future<void> updateQuantity({required String listingId, required int quantity}) async {
    final entries = List<CartEntry>.of(await _repository.loadCart());
    final index = entries.indexWhere((entry) => entry.listingId == listingId);
    if (index == -1) return;
    if (quantity <= 0) {
      entries.removeAt(index);
    } else {
      entries[index] = entries[index].copyWith(quantity: quantity);
    }
    await _repository.saveCart(entries);
  }

  Future<void> removeItem(String listingId) async {
    final entries = List<CartEntry>.of(await _repository.loadCart());
    entries.removeWhere((entry) => entry.listingId == listingId);
    await _repository.saveCart(entries);
  }

  Future<List<CartItemSummary>> getCartItems() async {
    final entries = await _repository.loadCart();
    final items = <CartItemSummary>[];
    for (var entry in entries) {
      final listing = await _listingRepository.getById(entry.listingId);
      if (listing != null) {
        items.add(CartItemSummary(entry: entry, listing: listing));
      }
    }
    return items;
  }

  Future<List<Listing>> getCartListings() async {
    final items = await getCartItems();
    return items.map((item) => item.listing).toList(growable: false);
  }

  Future<double> getCartTotal() async {
    final items = await getCartItems();
    return items.fold<double>(
        0.0,
        (total, item) =>
            total +
            (item.entry.offeredPricePerUnit ?? item.listing.pricePerUnit) *
                item.entry.quantity);
  }
}
