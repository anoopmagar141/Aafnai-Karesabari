import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

enum SellerApplicationStatus { pending, approved, rejected }

class SellerApplication {
  const SellerApplication({
    required this.id,
    required this.applicantId,
    required this.status,
    required this.businessName,
    required this.businessDescription,
    required this.businessAddress,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final String id;
  final String applicantId;
  final SellerApplicationStatus status;
  final String businessName;
  final String businessDescription;
  final String businessAddress;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  SellerApplication copyWith({
    String? id,
    String? applicantId,
    SellerApplicationStatus? status,
    String? businessName,
    String? businessDescription,
    String? businessAddress,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return SellerApplication(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      status: status ?? this.status,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessAddress: businessAddress ?? this.businessAddress,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'applicantId': applicantId,
        'status': status.name,
        'businessName': businessName,
        'businessDescription': businessDescription,
        'businessAddress': businessAddress,
        'submittedAt': timestampToFirestore(submittedAt),
        'reviewedAt': timestampToFirestoreNullable(reviewedAt),
        'reviewedBy': reviewedBy,
        'rejectionReason': rejectionReason,
      };

  factory SellerApplication.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return SellerApplication.fromMap(data);
  }

  factory SellerApplication.fromMap(Map<String, Object?> map) {
    return SellerApplication(
      id: map['id']! as String,
      applicantId: map['applicantId']! as String,
      status: SellerApplicationStatus.values.byName(map['status']! as String),
      businessName: map['businessName']! as String,
      businessDescription: map['businessDescription']! as String,
      businessAddress: (map['businessAddress'] ?? '') as String,
      submittedAt: timestampFromFirestoreRequired(map['submittedAt']),
      reviewedAt: timestampFromFirestore(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SellerApplication &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            applicantId == other.applicantId &&
            status == other.status &&
            businessName == other.businessName &&
            businessDescription == other.businessDescription &&
            submittedAt == other.submittedAt &&
            reviewedAt == other.reviewedAt &&
            reviewedBy == other.reviewedBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        applicantId,
        status,
        businessName,
        businessDescription,
        submittedAt,
        reviewedAt,
        reviewedBy,
      );
}
