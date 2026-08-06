import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';

Future<T> runFirestore<T>(
  Future<T> Function() action, {
  String? message,
}) async {
  try {
    return await action();
  } on FirebaseException catch (error) {
    throw AppException(message ?? error.message ?? 'Firestore request failed.');
  } catch (error) {
    final description = error.toString();
    if (description.contains('[core/no-app]') ||
        description.contains('Firebase')) {
      throw AppException(message ?? 'Firebase is not configured.');
    }
    throw AppException(message ?? 'Unexpected Firestore error.');
  }
}

List<T> mapQuerySnapshot<T>(
  QuerySnapshot<Map<String, dynamic>> snapshot,
  T Function(DocumentSnapshot<Map<String, dynamic>> doc) mapper,
) {
  return snapshot.docs.map(mapper).toList(growable: false);
}

Stream<T?> mapDocumentStream<T>(
  DocumentReference<Map<String, dynamic>> reference,
  T Function(DocumentSnapshot<Map<String, dynamic>> doc) mapper,
) {
  return reference.snapshots().map((snapshot) {
    if (!snapshot.exists) return null;
    return mapper(snapshot);
  });
}

Stream<List<T>> mapCollectionStream<T>(
  Query<Map<String, dynamic>> query,
  T Function(DocumentSnapshot<Map<String, dynamic>> doc) mapper,
) {
  return query.snapshots().map(
        (snapshot) => mapQuerySnapshot(snapshot, mapper),
      );
}
