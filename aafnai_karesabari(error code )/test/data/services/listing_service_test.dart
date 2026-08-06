import 'package:flutter_test/flutter_test.dart';
import 'package:aafnai_karesabari/data/models/listing.dart';
import 'package:aafnai_karesabari/data/repositories/listing_repository.dart';
import 'package:aafnai_karesabari/data/services/listing_service.dart';

void main() {
  late LocalListingRepository repository;
  late ListingService service;

  setUp(() {
    repository = LocalListingRepository(seed: {});
    service = ListingService(
      firestoreRepository: repository,
      localRepository: repository,
    );
  });

  const draftData = ListingFormData(
    title: 'Fresh Tomatoes',
    description: 'Locally grown',
    price: 0,
    quantity: 0,
    category: ListingCategory.vegetable,
    unit: ListingUnit.kg,
    location: '',
  );

  const publishData = ListingFormData(
    title: 'Fresh Tomatoes',
    description: 'Locally grown',
    price: 120,
    quantity: 12,
    category: ListingCategory.vegetable,
    unit: ListingUnit.kg,
    location: 'Lalitpur',
    photoUrls: ['https://example.com/tomato.jpg'],
  );

  group('ListingService validation', () {
    test('allows partial data for drafts', () {
      final result = service.validate(draftData, forPublish: false);
      expect(result.isValid, isTrue);
    });

    test('requires price, quantity, and location to publish', () {
      final result = service.validate(draftData, forPublish: true);
      expect(result.isValid, isFalse);
      expect(result.errorFor('price'), isNotNull);
      expect(result.errorFor('quantity'), isNotNull);
      expect(result.errorFor('location'), isNotNull);
    });
  });

  group('ListingService CRUD', () {
    test('creates, edits, publishes, unpublishes, and deletes listings', () async {
      final draft = await service.createDraft(
        data: draftData,
        farmerId: 'farmer-1',
      );
      expect(draft.status, ListingStatus.draft);

      final edited = await service.saveDraft(
        data: publishData.copyWith(title: 'Vine Tomatoes'),
        farmerId: 'farmer-1',
        listingId: draft.id,
      );
      expect(edited.productName, 'Vine Tomatoes');
      expect(edited.status, ListingStatus.draft);

      final published = await service.publish(
        data: publishData.copyWith(title: 'Vine Tomatoes'),
        farmerId: 'farmer-1',
        listingId: draft.id,
      );
      expect(published.status, ListingStatus.active);

      final unpublished = await service.unpublish(draft.id);
      expect(unpublished.status, ListingStatus.draft);

      await service.deleteListing(draft.id);
      expect(await service.getById(draft.id), isNull);
    });
  });
}

extension on ListingFormData {
  ListingFormData copyWith({
    String? title,
    String? description,
    double? price,
    int? quantity,
    ListingCategory? category,
    ListingUnit? unit,
    String? location,
    List<String>? photoUrls,
  }) {
    return ListingFormData(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}
