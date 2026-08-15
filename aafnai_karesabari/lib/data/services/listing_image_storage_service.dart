import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/errors/app_exception.dart';

Future<T> runStorage<T>(Future<T> Function() action, {String? message}) async {
  try {
    return await action();
  } on FirebaseException catch (error) {
    throw AppException(message ?? error.message ?? 'Storage request failed.');
  } catch (error) {
    final description = error.toString();
    if (description.contains('[core/no-app]') ||
        description.contains('Firebase')) {
      throw AppException(message ?? 'Firebase is not configured.');
    }
    throw AppException(message ?? 'Unexpected storage error.');
  }
}

/// Uploads/replaces/deletes a listing's photo in Firebase Storage.
/// Currently unused in practice — the app represents products with
/// vector icons (see [iconForListing]) to stay within the free storage
/// tier — but kept as the upload path if photo listings are added later.
abstract class ListingImageStorageService {
  Future<String> upload({
    required String farmerId,
    required String listingId,
    required Uint8List bytes,
    required String fileName,
    String contentType,
  });

  Future<void> delete({required String imageUrl});

  Future<String> replace({
    required String farmerId,
    required String listingId,
    required String existingUrl,
    required Uint8List bytes,
    required String fileName,
    String contentType,
  });
}

class FirebaseListingImageStorageService implements ListingImageStorageService {
  FirebaseListingImageStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference _photoRef({
    required String farmerId,
    required String listingId,
    required String fileName,
  }) {
    return _storage.ref().child(
          'listing_photos/$farmerId/$listingId/${_safeFileName(fileName)}',
        );
  }

  @override
  Future<String> upload({
    required String farmerId,
    required String listingId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    return runStorage(() async {
      final reference = _photoRef(
        farmerId: farmerId,
        listingId: listingId,
        fileName: fileName,
      );
      await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      return reference.getDownloadURL();
    }, message: 'Unable to upload photo.');
  }

  @override
  Future<void> delete({required String imageUrl}) {
    if (isLocalPlaceholderUrl(imageUrl)) return Future.value();
    return runStorage(
      () => _storage.refFromURL(imageUrl).delete(),
      message: 'Unable to delete photo.',
    );
  }

  @override
  Future<String> replace({
    required String farmerId,
    required String listingId,
    required String existingUrl,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    await delete(imageUrl: existingUrl);
    return upload(
      farmerId: farmerId,
      listingId: listingId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}

class LocalListingImageStorageService implements ListingImageStorageService {
  int _counter = 0;

  @override
  Future<String> upload({
    required String farmerId,
    required String listingId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    _counter++;
    return buildLocalPlaceholderUrl(
      farmerId: farmerId,
      listingId: listingId,
      fileName: '${_safeFileName(fileName)}-$_counter',
    );
  }

  @override
  Future<void> delete({required String imageUrl}) async {}

  @override
  Future<String> replace({
    required String farmerId,
    required String listingId,
    required String existingUrl,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    return upload(
      farmerId: farmerId,
      listingId: listingId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}

class ResilientListingImageStorageService implements ListingImageStorageService {
  ResilientListingImageStorageService({
    ListingImageStorageService? primary,
    ListingImageStorageService? fallback,
  })  : _primary = primary ?? FirebaseListingImageStorageService(),
        _fallback = fallback ?? LocalListingImageStorageService();

  final ListingImageStorageService _primary;
  final ListingImageStorageService _fallback;

  @override
  Future<String> upload({
    required String farmerId,
    required String listingId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    return _execute(
      (service) => service.upload(
        farmerId: farmerId,
        listingId: listingId,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      ),
    );
  }

  @override
  Future<void> delete({required String imageUrl}) {
    return _execute((service) => service.delete(imageUrl: imageUrl));
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
    return _execute(
      (service) => service.replace(
        farmerId: farmerId,
        listingId: listingId,
        existingUrl: existingUrl,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      ),
    );
  }

  Future<T> _execute<T>(
    Future<T> Function(ListingImageStorageService service) action,
  ) async {
    try {
      return await action(_primary);
    } on AppException {
      return action(_fallback);
    }
  }
}

const localPlaceholderScheme = 'local-placeholder://';

bool isLocalPlaceholderUrl(String url) => url.startsWith(localPlaceholderScheme);

String buildLocalPlaceholderUrl({
  required String farmerId,
  required String listingId,
  required String fileName,
}) {
  return '$localPlaceholderScheme$farmerId/$listingId/$fileName';
}

String _safeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
}
