import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seller_application.dart';
import 'firestore_repository.dart';

final sellerApplicationRepositoryProvider = Provider<SellerApplicationRepository>(
  (ref) => FirestoreSellerApplicationRepository(),
);

/// CRUD + a live pending-applications stream, backing the admin Seller
/// Verification queue.
abstract class SellerApplicationRepository {
  Future<SellerApplication> createApplication(SellerApplication application);
  Future<SellerApplication?> getApplication(String id);
  Future<List<SellerApplication>> getUserApplications(String userId);
  Future<List<SellerApplication>> getPendingApplications();
  Stream<List<SellerApplication>> getPendingApplicationsStream();
  Future<void> updateApplicationStatus(String id, SellerApplicationStatus status, String adminId, {String? rejectionReason});
}

class FirestoreSellerApplicationRepository implements SellerApplicationRepository {
  FirestoreSellerApplicationRepository({FirebaseFirestore? firestore})
      : _applications = (firestore ?? FirebaseFirestore.instance).collection('seller_applications');

  final CollectionReference<Map<String, dynamic>> _applications;

  @override
  Future<SellerApplication> createApplication(SellerApplication application) => runFirestore(() async {
        await _applications.doc(application.id).set(application.toFirestore());
        return application;
      }, message: 'Unable to submit seller application.');

  @override
  Future<SellerApplication?> getApplication(String id) => runFirestore(() async {
        final snapshot = await _applications.doc(id).get();
        if (!snapshot.exists) return null;
        return SellerApplication.fromFirestore(snapshot);
      }, message: 'Unable to load seller application.');

  @override
  Future<List<SellerApplication>> getUserApplications(String userId) => runFirestore(() async {
        final query = _applications
            .where('applicantId', isEqualTo: userId)
            .orderBy('submittedAt', descending: true);
        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, SellerApplication.fromFirestore);
      }, message: 'Unable to load user applications.');

  @override
  Future<List<SellerApplication>> getPendingApplications() => runFirestore(() async {
        final query = _applications
            .where('status', isEqualTo: SellerApplicationStatus.pending.name)
            .orderBy('submittedAt', descending: true);
        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, SellerApplication.fromFirestore);
      }, message: 'Unable to load pending applications.');

  @override
  Stream<List<SellerApplication>> getPendingApplicationsStream() => _applications
      .where('status', isEqualTo: SellerApplicationStatus.pending.name)
      .snapshots()
      .map((snapshot) => mapQuerySnapshot(snapshot, SellerApplication.fromFirestore));

  @override
  Future<void> updateApplicationStatus(String id, SellerApplicationStatus status, String adminId, {String? rejectionReason}) => runFirestore(() async {
    final data = <String, dynamic>{
      'status': status.name,
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) {
      data['rejectionReason'] = rejectionReason;
    }
    await _applications.doc(id).update(data);
  }, message: 'Unable to update application status.');
}
