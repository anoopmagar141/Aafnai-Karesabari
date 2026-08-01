import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:aafnai_karesabari/core/errors/app_exception.dart';
import 'package:aafnai_karesabari/data/services/listing_image_storage_service.dart';

void main() {
  late LocalListingImageStorageService service;
  final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);

  setUp(() {
    service = LocalListingImageStorageService();
  });

  test('upload returns a local placeholder URL', () async {
    final url = await service.upload(
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      bytes: sampleBytes,
      fileName: 'tomato.jpg',
    );

    expect(isLocalPlaceholderUrl(url), isTrue);
    expect(url, contains('farmer-1'));
    expect(url, contains('listing-1'));
  });

  test('replace returns a new placeholder URL', () async {
    final original = await service.upload(
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      bytes: sampleBytes,
      fileName: 'tomato.jpg',
    );

    final replaced = await service.replace(
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      existingUrl: original,
      bytes: sampleBytes,
      fileName: 'tomato-v2.jpg',
    );

    expect(replaced, isNot(original));
    expect(isLocalPlaceholderUrl(replaced), isTrue);
  });

  test('delete completes without error for placeholders', () async {
    final url = await service.upload(
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      bytes: sampleBytes,
      fileName: 'tomato.jpg',
    );

    await expectLater(service.delete(imageUrl: url), completes);
  });

  test('resilient service falls back when Firebase upload fails', () async {
    final failing = _FailingStorageService();
    final fallback = LocalListingImageStorageService();
    final resilient = ResilientListingImageStorageService(
      primary: failing,
      fallback: fallback,
    );

    final url = await resilient.upload(
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      bytes: sampleBytes,
      fileName: 'spinach.jpg',
    );

    expect(isLocalPlaceholderUrl(url), isTrue);
  });
}

class _FailingStorageService implements ListingImageStorageService {
  @override
  Future<void> delete({required String imageUrl}) {
    throw const AppException('Storage unavailable.');
  }

  @override
  Future<String> replace({
    required String farmerId,
    required String listingId,
    required String existingUrl,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    throw const AppException('Storage unavailable.');
  }

  @override
  Future<String> upload({
    required String farmerId,
    required String listingId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    throw const AppException('Storage unavailable.');
  }
}
