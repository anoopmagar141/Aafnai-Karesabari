import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/market_price.dart';
import 'firestore_repository.dart';

class MarketPriceListFilter {
  const MarketPriceListFilter({
    this.productName,
    this.region,
    this.limit,
  });

  final String? productName;
  final String? region;
  final int? limit;
}

abstract class MarketPriceRepository {
  Future<MarketPrice> create(MarketPrice price);
  Future<void> update(MarketPrice price);
  Future<void> delete(String priceId);
  Future<MarketPrice?> getById(String priceId);
  Stream<MarketPrice?> stream(String priceId);
  Future<List<MarketPrice>> list({MarketPriceListFilter? filter});
}

class FirestoreMarketPriceRepository implements MarketPriceRepository {
  FirestoreMarketPriceRepository({FirebaseFirestore? firestore})
      : _prices = (firestore ?? FirebaseFirestore.instance)
            .collection('price_history');

  final CollectionReference<Map<String, dynamic>> _prices;

  @override
  Future<MarketPrice> create(MarketPrice price) => runFirestore(() async {
        await _prices.doc(price.id).set(price.toFirestore());
        return price;
      }, message: 'Unable to create market price.');

  @override
  Future<void> update(MarketPrice price) => runFirestore(
        () => _prices
            .doc(price.id)
            .set(price.toFirestore(), SetOptions(merge: true)),
        message: 'Unable to update market price.',
      );

  @override
  Future<void> delete(String priceId) => runFirestore(
        () => _prices.doc(priceId).delete(),
        message: 'Unable to delete market price.',
      );

  @override
  Future<MarketPrice?> getById(String priceId) => runFirestore(() async {
        final snapshot = await _prices.doc(priceId).get();
        if (!snapshot.exists) return null;
        return MarketPrice.fromFirestore(snapshot);
      }, message: 'Unable to load market price.');

  @override
  Stream<MarketPrice?> stream(String priceId) {
    return mapDocumentStream(_prices.doc(priceId), MarketPrice.fromFirestore);
  }

  @override
  Future<List<MarketPrice>> list({MarketPriceListFilter? filter}) =>
      runFirestore(() async {
        Query<Map<String, dynamic>> query =
            _prices.orderBy('recorded_at', descending: true);

        final productName = filter?.productName;
        if (productName != null) {
          query = query.where('product_name', isEqualTo: productName);
        }

        final region = filter?.region;
        if (region != null) {
          query = query.where('region', isEqualTo: region);
        }

        final limit = filter?.limit;
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, MarketPrice.fromFirestore);
      }, message: 'Unable to load market prices.');
}

class LocalMarketPriceRepository implements MarketPriceRepository {
  LocalMarketPriceRepository({Map<String, MarketPrice>? seed})
      : _prices = Map<String, MarketPrice>.from(seed ?? _defaultSeed);

  static final Map<String, MarketPrice> _defaultSeed = {
    'tomatoes-kathmandu': MarketPrice(
      id: 'tomatoes-kathmandu',
      productName: 'Tomatoes',
      region: 'Kathmandu',
      low: 90,
      average: 120,
      high: 150,
      recordedAt: DateTime(2026, 7, 28),
    ),
    'spinach-lalitpur': MarketPrice(
      id: 'spinach-lalitpur',
      productName: 'Spinach',
      region: 'Lalitpur',
      low: 60,
      average: 80,
      high: 100,
      recordedAt: DateTime(2026, 7, 28),
    ),
  };

  final Map<String, MarketPrice> _prices;

  @override
  Future<MarketPrice> create(MarketPrice price) async {
    _prices[price.id] = price;
    return price;
  }

  @override
  Future<void> update(MarketPrice price) async {
    _prices[price.id] = price;
  }

  @override
  Future<void> delete(String priceId) async {
    _prices.remove(priceId);
  }

  @override
  Future<MarketPrice?> getById(String priceId) async => _prices[priceId];

  @override
  Stream<MarketPrice?> stream(String priceId) async* {
    yield _prices[priceId];
  }

  @override
  Future<List<MarketPrice>> list({MarketPriceListFilter? filter}) async {
    var results = _prices.values.toList();
    final productName = filter?.productName;
    if (productName != null) {
      results =
          results.where((price) => price.productName == productName).toList();
    }
    final region = filter?.region;
    if (region != null) {
      results = results.where((price) => price.region == region).toList();
    }
    results.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final limit = filter?.limit;
    if (limit != null) {
      return results.take(limit).toList(growable: false);
    }
    return results;
  }
}
