import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/listing.dart';
import 'firestore_repository.dart';

class ListingListFilter {
  const ListingListFilter({
    this.farmerId,
    this.category,
    this.status,
    this.limit,
  });

  final String? farmerId;
  final ListingCategory? category;
  final ListingStatus? status;
  final int? limit;
}

abstract class ListingRepository {
  Future<Listing> create(Listing listing);
  Future<void> update(Listing listing);
  Future<void> delete(String listingId);
  Future<Listing?> getById(String listingId);
  Stream<Listing?> stream(String listingId);
  Future<List<Listing>> list({ListingListFilter? filter});
}

class FirestoreListingRepository implements ListingRepository {
  FirestoreListingRepository({FirebaseFirestore? firestore})
      : _listings =
            (firestore ?? FirebaseFirestore.instance).collection('listings');

  final CollectionReference<Map<String, dynamic>> _listings;

  @override
  Future<Listing> create(Listing listing) => runFirestore(() async {
        await _listings.doc(listing.id).set(listing.toFirestore());
        return listing;
      }, message: 'Unable to create listing.');

  @override
  Future<void> update(Listing listing) => runFirestore(
        () => _listings
            .doc(listing.id)
            .set(listing.toFirestore(), SetOptions(merge: true)),
        message: 'Unable to update listing.',
      );

  @override
  Future<void> delete(String listingId) => runFirestore(
        () => _listings.doc(listingId).delete(),
        message: 'Unable to delete listing.',
      );

  @override
  Future<Listing?> getById(String listingId) => runFirestore(() async {
        final snapshot = await _listings.doc(listingId).get();
        if (!snapshot.exists) return null;
        return Listing.fromFirestore(snapshot);
      }, message: 'Unable to load listing.');

  @override
  Stream<Listing?> stream(String listingId) {
    return mapDocumentStream(_listings.doc(listingId), Listing.fromFirestore);
  }

  @override
  Future<List<Listing>> list({ListingListFilter? filter}) =>
      runFirestore(() async {
        Query<Map<String, dynamic>> query =
            _listings.orderBy('created_at', descending: true);

        final farmerId = filter?.farmerId;
        if (farmerId != null) {
          query = query.where('farmer_id', isEqualTo: farmerId);
        }

        final category = filter?.category;
        if (category != null) {
          query = query.where('category', isEqualTo: category.name);
        }

        final status = filter?.status;
        if (status != null) {
          query = query.where('status', isEqualTo: status.name);
        }

        final limit = filter?.limit;
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, Listing.fromFirestore);
      }, message: 'Unable to load listings.');
}

class LocalListingRepository implements ListingRepository {
  LocalListingRepository({Map<String, Listing>? seed})
      : _listings = Map<String, Listing>.from(seed ?? _defaultSeed);

  static final Map<String, Listing> _defaultSeed = {
    'tomatoes': Listing(
      id: 'tomatoes',
      farmerId: 'sita',
      productName: 'Fresh Tomatoes',
      category: ListingCategory.vegetable,
      pricePerUnit: 120,
      unit: ListingUnit.kg,
      stockQuantity: 12,
      status: ListingStatus.active,
      createdAt: DateTime(2026, 7, 1),
      displayIcon: Icons.local_florist,
      isFeatured: true,
    ),
    'spinach': Listing(
      id: 'spinach',
      farmerId: 'hari',
      productName: 'Organic Spinach',
      category: ListingCategory.vegetable,
      pricePerUnit: 80,
      unit: ListingUnit.kg,
      stockQuantity: 6,
      status: ListingStatus.active,
      createdAt: DateTime(2026, 7, 2),
      displayIcon: Icons.grass,
    ),
    'oranges': Listing(
      id: 'oranges',
      farmerId: 'maya',
      productName: 'Sweet Oranges',
      category: ListingCategory.fruit,
      pricePerUnit: 180,
      unit: ListingUnit.kg,
      stockQuantity: 20,
      status: ListingStatus.active,
      createdAt: DateTime(2026, 7, 3),
      displayIcon: Icons.circle,
    ),
    'eggs': Listing(
      id: 'eggs',
      farmerId: 'laxmi',
      productName: 'Free-range Eggs',
      category: ListingCategory.grain,
      pricePerUnit: 240,
      unit: ListingUnit.piece,
      stockQuantity: 18,
      status: ListingStatus.active,
      createdAt: DateTime(2026, 7, 4),
      displayIcon: Icons.egg_alt,
    ),
  };

  final Map<String, Listing> _listings;

  @override
  Future<Listing> create(Listing listing) async {
    _listings[listing.id] = listing;
    return listing;
  }

  @override
  Future<void> update(Listing listing) async {
    _listings[listing.id] = listing;
  }

  @override
  Future<void> delete(String listingId) async {
    _listings.remove(listingId);
  }

  @override
  Future<Listing?> getById(String listingId) async => _listings[listingId];

  @override
  Stream<Listing?> stream(String listingId) async* {
    yield _listings[listingId];
  }

  @override
  Future<List<Listing>> list({ListingListFilter? filter}) async {
    var results = _listings.values.toList();
    final farmerId = filter?.farmerId;
    if (farmerId != null) {
      results = results.where((listing) => listing.farmerId == farmerId).toList();
    }
    final category = filter?.category;
    if (category != null) {
      results = results.where((listing) => listing.category == category).toList();
    }
    final status = filter?.status;
    if (status != null) {
      results = results.where((listing) => listing.status == status).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limit = filter?.limit;
    if (limit != null) {
      return results.take(limit).toList(growable: false);
    }
    return results;
  }
}
