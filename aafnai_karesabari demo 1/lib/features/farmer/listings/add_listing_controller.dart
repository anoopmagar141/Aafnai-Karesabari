import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/listing.dart';
import '../../../data/services/listing_image_storage_service.dart';
import '../../../data/services/listing_service.dart';


final listingImageStorageProvider = Provider<ListingImageStorageService>(
  (ref) => ResilientListingImageStorageService(),
);

class ListingDraft {
  const ListingDraft({
    this.listingId,
    this.title = '',
    this.description = '',
    this.price,
    this.quantity = 0,
    this.category = ListingCategory.vegetable,
    this.unit = ListingUnit.kg,
    this.location = '',
    this.photoUrls = const [],
    this.isSaving = false,
    this.isUploadingPhoto = false,
    this.errorMessage,
  });

  final String? listingId;
  final String title;
  final String description;
  final double? price;
  final int quantity;
  final ListingCategory category;
  final ListingUnit unit;
  final String location;
  final List<String> photoUrls;
  final bool isSaving;
  final bool isUploadingPhoto;
  final String? errorMessage;

  bool get isEditing => listingId != null;

  ListingFormData toFormData() {
    return ListingFormData(
      title: title,
      description: description.isEmpty ? null : description,
      price: price ?? 0,
      quantity: quantity,
      category: category,
      unit: unit,
      location: location,
      photoUrls: photoUrls,
    );
  }

  ListingDraft copyWith({
    String? listingId,
    String? title,
    String? description,
    double? price,
    int? quantity,
    ListingCategory? category,
    ListingUnit? unit,
    String? location,
    List<String>? photoUrls,
    bool? isSaving,
    bool? isUploadingPhoto,
    String? errorMessage,
  }) {
    return ListingDraft(
      listingId: listingId ?? this.listingId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      isSaving: isSaving ?? this.isSaving,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      errorMessage: errorMessage,
    );
  }

  factory ListingDraft.fromListing(Listing listing) {
    return ListingDraft(
      listingId: listing.id,
      title: listing.productName,
      description: listing.description ?? '',
      price: listing.pricePerUnit,
      quantity: listing.stockQuantity,
      category: listing.category,
      unit: listing.unit,
      location: listing.location ?? '',
      photoUrls: listing.photoUrls,
    );
  }
}

class ListingDraftNotifier extends StateNotifier<ListingDraft> {
  ListingDraftNotifier(this._service, this._imageStorage)
      : super(const ListingDraft());

  final ListingService _service;
  final ListingImageStorageService _imageStorage;

  String _storageListingId(String farmerId) =>
      state.listingId ?? 'draft-$farmerId';

  void loadFromListing(Listing listing) {
    state = ListingDraft.fromListing(listing);
  }

  void reset() {
    state = const ListingDraft();
  }

  void updateDraft({
    String? title,
    String? description,
    double? price,
    int? quantity,
    ListingCategory? category,
    ListingUnit? unit,
    String? location,
    List<String>? photoUrls,
  }) {
    state = state.copyWith(
      title: title,
      description: description,
      price: price,
      quantity: quantity,
      category: category,
      unit: unit,
      location: location,
      photoUrls: photoUrls,
      errorMessage: null,
    );
  }

  void addPhotoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || state.photoUrls.contains(trimmed)) return;
    state = state.copyWith(
      photoUrls: [...state.photoUrls, trimmed],
      errorMessage: null,
    );
  }

  void removePhotoUrl(String url) {
    state = state.copyWith(
      photoUrls: state.photoUrls.where((item) => item != url).toList(),
      errorMessage: null,
    );
  }

  Future<void> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
    required String farmerId,
    String contentType = 'image/jpeg',
  }) async {
    state = state.copyWith(isUploadingPhoto: true, errorMessage: null);
    try {
      final url = await _imageStorage.upload(
        farmerId: farmerId,
        listingId: _storageListingId(farmerId),
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      state = state.copyWith(
        photoUrls: [...state.photoUrls, url],
        isUploadingPhoto: false,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        isUploadingPhoto: false,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        isUploadingPhoto: false,
        errorMessage: 'Unable to upload photo right now.',
      );
    }
  }

  Future<void> replacePhoto({
    required String existingUrl,
    required Uint8List bytes,
    required String fileName,
    required String farmerId,
    String contentType = 'image/jpeg',
  }) async {
    state = state.copyWith(isUploadingPhoto: true, errorMessage: null);
    try {
      final url = await _imageStorage.replace(
        farmerId: farmerId,
        listingId: _storageListingId(farmerId),
        existingUrl: existingUrl,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      final updatedUrls = state.photoUrls
          .map((item) => item == existingUrl ? url : item)
          .toList(growable: false);
      state = state.copyWith(
        photoUrls: updatedUrls,
        isUploadingPhoto: false,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        isUploadingPhoto: false,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        isUploadingPhoto: false,
        errorMessage: 'Unable to replace photo right now.',
      );
    }
  }

  Future<void> removePhoto(String url) async {
    try {
      await _imageStorage.delete(imageUrl: url);
    } on AppException {
      // Allow local placeholders and graceful cleanup even if remote delete fails.
    }
    removePhotoUrl(url);
  }

  Future<Listing?> saveDraft(String farmerId) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final validation = _service.validate(state.toFormData(), forPublish: false);
      if (!validation.isValid) {
        throw ListingValidationException(validation);
      }

      final listing = state.isEditing
          ? await _service.saveDraft(
              data: state.toFormData(),
              farmerId: farmerId,
              listingId: state.listingId!,
            )
          : await _service.createDraft(
              data: state.toFormData(),
              farmerId: farmerId,
            );

      state = ListingDraft.fromListing(listing).copyWith(isSaving: false);
      return listing;
    } on ListingValidationException catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.result.errors.values.first,
      );
      return null;
    } on AppException catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to save draft right now.',
      );
      return null;
    }
  }

  Future<Listing?> publish(String farmerId) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final listing = await _service.publish(
        data: state.toFormData(),
        farmerId: farmerId,
        listingId: state.listingId,
      );
      state = ListingDraft.fromListing(listing).copyWith(isSaving: false);
      return listing;
    } on ListingValidationException catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.result.errors.values.first,
      );
      return null;
    } on AppException catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to publish listing right now.',
      );
      return null;
    }
  }
}

final listingDraftProvider =
    StateNotifierProvider<ListingDraftNotifier, ListingDraft>(
  (ref) => ListingDraftNotifier(
    ref.watch(listingServiceProvider),
    ref.watch(listingImageStorageProvider),
  ),
);

final farmerListingsProvider =
    FutureProvider.family<List<Listing>, String>((ref, farmerId) {
  return ref.watch(listingServiceProvider).listForFarmer(farmerId);
});
