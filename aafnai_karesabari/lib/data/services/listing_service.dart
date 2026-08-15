import '../../core/errors/app_exception.dart';
import '../models/listing.dart';
import '../repositories/listing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingServiceProvider = Provider<ListingService>((ref) => ListingService());

class ListingValidationResult {
  const ListingValidationResult({this.errors = const {}});

  final Map<String, String> errors;

  bool get isValid => errors.isEmpty;

  String? errorFor(String field) => errors[field];
}

class ListingValidationException implements Exception {
  const ListingValidationException(this.result);

  final ListingValidationResult result;

  @override
  String toString() => result.errors.values.join('\n');
}

/// Validates and persists a farmer's product listing (price, quantity,
/// bargaining rules), delegating storage to [ListingRepository] with a
/// local fallback when Firestore is unreachable.
class ListingService {
  ListingService({
    ListingRepository? firestoreRepository,
    ListingRepository? localRepository,
  })  : _firestore = firestoreRepository ?? FirestoreListingRepository(),
        _local = localRepository ?? LocalListingRepository();

  final ListingRepository _firestore;
  final ListingRepository _local;

  ListingValidationResult validate(
    ListingFormData data, {
    required bool forPublish,
  }) {
    final errors = <String, String>{};
    final title = data.title.trim();

    if (title.length < 2) {
      errors['title'] = 'Enter a product title with at least 2 characters.';
    }

    if (data.description != null && data.description!.trim().length > 500) {
      errors['description'] = 'Description must be 500 characters or fewer.';
    }

    if (forPublish) {
      if (data.price <= 0) {
        errors['price'] = 'Enter a price greater than zero.';
      }
      if (data.quantity <= 0) {
        errors['quantity'] = 'Enter a quantity greater than zero.';
      }
      if (data.location.trim().isEmpty) {
        errors['location'] = 'Enter your farm location.';
      }
    }

    final minBargainPrice = data.minBargainPrice;
    if (minBargainPrice != null) {
      if (minBargainPrice <= 0) {
        errors['minBargainPrice'] = 'Minimum offer price must be greater than zero.';
      } else if (minBargainPrice > data.price) {
        errors['minBargainPrice'] =
            'Minimum offer price cannot be higher than the listed price.';
      }
    }

    return ListingValidationResult(errors: errors);
  }

  Future<Listing> createDraft({
    required ListingFormData data,
    required String farmerId,
  }) async {
    final listing = _toListing(
      data: data,
      farmerId: farmerId,
      status: ListingStatus.draft,
    );
    return _create(listing);
  }

  Future<Listing> saveDraft({
    required ListingFormData data,
    required String farmerId,
    required String listingId,
  }) async {
    final existing = await getById(listingId);
    final listing = _toListing(
      data: data,
      farmerId: farmerId,
      listingId: listingId,
      status: ListingStatus.draft,
      createdAt: existing?.createdAt,
    );
    await _update(listing);
    return listing;
  }

  Future<Listing> publish({
    required ListingFormData data,
    required String farmerId,
    String? listingId,
  }) async {
    final validation = validate(data, forPublish: true);
    if (!validation.isValid) {
      throw ListingValidationException(validation);
    }

    final existing = listingId == null ? null : await getById(listingId);
    final listing = _toListing(
      data: data,
      farmerId: farmerId,
      listingId: listingId,
      status: ListingStatus.active,
      createdAt: existing?.createdAt,
    );

    if (listingId == null) {
      return _create(listing);
    }

    await _update(listing);
    return listing;
  }

  Future<Listing> unpublish(String listingId) async {
    final listing = await getById(listingId);
    if (listing == null) {
      throw const AppException('Listing not found.');
    }

    final updated = listing.copyWith(
      status: ListingStatus.draft,
      updatedAt: DateTime.now(),
    );
    await _update(updated);
    return updated;
  }

  Future<void> deleteListing(String listingId) async {
    await _run((repository) => repository.delete(listingId));
  }

  Future<Listing?> getById(String listingId) =>
      _run((repository) => repository.getById(listingId));

  Future<List<Listing>> list({ListingListFilter? filter}) => _run(
        (repository) => repository.list(filter: filter),
      );

  Future<List<Listing>> listForFarmer(String farmerId) => _run(
        (repository) => repository.list(
          filter: ListingListFilter(farmerId: farmerId),
        ),
      );

  Listing _toListing({
    required ListingFormData data,
    required String farmerId,
    required ListingStatus status,
    String? listingId,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return Listing(
      id: listingId ?? _generateListingId(),
      farmerId: farmerId,
      productName: data.title.trim(),
      description: data.description?.trim().isEmpty ?? true
          ? null
          : data.description!.trim(),
      category: data.category,
      pricePerUnit: data.price,
      unit: data.unit,
      stockQuantity: data.quantity,
      location: data.location.trim().isEmpty ? null : data.location.trim(),
      photoUrls: data.photoUrls,
      status: status,
      createdAt: createdAt ?? now,
      updatedAt: now,
      minBargainPrice: data.minBargainPrice,
    );
  }

  String _generateListingId() =>
      'listing-${DateTime.now().millisecondsSinceEpoch}';

  Future<Listing> _create(Listing listing) =>
      _run((repository) => repository.create(listing));

  Future<void> _update(Listing listing) =>
      _run((repository) => repository.update(listing));

  Future<T> _run<T>(Future<T> Function(ListingRepository repository) action) async {
    try {
      return await action(_firestore);
    } on AppException {
      return await action(_local);
    }
  }
}

class ListingFormData {
  const ListingFormData({
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
    required this.unit,
    required this.location,
    this.photoUrls = const [],
    this.minBargainPrice,
  });

  final String title;
  final String? description;
  final double price;
  final int quantity;
  final ListingCategory category;
  final ListingUnit unit;
  final String location;
  final List<String> photoUrls;

  /// Lowest price per unit the seller will accept from a buyer's offer.
  /// Null means bargaining is disabled for this listing.
  final double? minBargainPrice;

  factory ListingFormData.fromListing(Listing listing) {
    return ListingFormData(
      title: listing.productName,
      description: listing.description,
      price: listing.pricePerUnit,
      quantity: listing.stockQuantity,
      category: listing.category,
      unit: listing.unit,
      location: listing.location ?? '',
      photoUrls: listing.photoUrls,
      minBargainPrice: listing.minBargainPrice,
    );
  }
}
