import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';
import '../repositories/listing_repository.dart';
import '../seed/sample_listings_data.dart';

final listingSeedServiceProvider = Provider<ListingSeedService>(
  (ref) => ListingSeedService(ref.watch(listingRepositoryProvider)),
);

/// Seeds the marketplace with a catalogue of ~50 sample listings so the app
/// has realistic browsing data without needing uploaded product photos.
class ListingSeedService {
  ListingSeedService(this._repository);

  final ListingRepository _repository;

  Future<int> seedSampleListings({required String farmerId}) async {
    final existing = await _repository.list(
      filter: ListingListFilter(farmerId: farmerId),
    );
    final existingIds = existing.map((listing) => listing.id).toSet();

    var created = 0;
    final now = DateTime.now();
    for (var i = 0; i < sampleListings.length; i++) {
      final sample = sampleListings[i];
      final id = 'seed-${sample.slug}';
      if (existingIds.contains(id)) continue;

      await _repository.create(Listing(
        id: id,
        farmerId: farmerId,
        productName: sample.productName,
        description: sample.description,
        category: sample.category,
        pricePerUnit: sample.pricePerUnit,
        unit: sample.unit,
        stockQuantity: sample.stockQuantity,
        location: sample.location,
        status: ListingStatus.active,
        createdAt: now.subtract(Duration(minutes: sampleListings.length - i)),
      ));
      created++;
    }
    return created;
  }
}
