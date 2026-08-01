import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum OtpValidationResult { verified, invalid, expired, tooManyAttempts, unavailable }

class SimulatedOtpService {
  SimulatedOtpService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const maxAttempts = 5;
  static const validity = Duration(minutes: 5);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> create(String phoneNumber) async {
    final user = await _ensureAnonymousSession();
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    final now = DateTime.now();
    // PRODUCTION: replace this generated/displayed code with Firebase Phone Auth
    // (Blaze) or a server-side SMS gateway/Cloud Function; never return OTPs to UI.
    await _document(phoneNumber).set({
      'code': code,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(validity)),
      'verified': false,
      'attempts': 0,
      'owner_uid': user.uid,
    });
    return code;
  }

  Future<OtpValidationResult> verify({required String phoneNumber, required String code}) async {
    final user = _auth.currentUser;
    if (user == null) return OtpValidationResult.unavailable;
    return _firestore.runTransaction((transaction) async {
      final reference = _document(phoneNumber);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data()?['owner_uid'] != user.uid) return OtpValidationResult.unavailable;
      final data = snapshot.data()!;
      final attempts = data['attempts'] as int? ?? 0;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (attempts >= maxAttempts) return OtpValidationResult.tooManyAttempts;
      if (!DateTime.now().isBefore(expiresAt)) return OtpValidationResult.expired;
      if (data['code'] != code) {
        transaction.update(reference, {'attempts': attempts + 1});
        return attempts + 1 >= maxAttempts ? OtpValidationResult.tooManyAttempts : OtpValidationResult.invalid;
      }
      transaction.update(reference, {'verified': true});
      return OtpValidationResult.verified;
    });
  }

  DocumentReference<Map<String, dynamic>> _document(String phoneNumber) => _firestore.collection('otp_verifications').doc(_documentId(phoneNumber));

  String _documentId(String phoneNumber) => base64Url.encode(utf8.encode(phoneNumber)).replaceAll('=', '');

  Future<User> _ensureAnonymousSession() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    return (await _auth.signInAnonymously()).user!;
  }
}
