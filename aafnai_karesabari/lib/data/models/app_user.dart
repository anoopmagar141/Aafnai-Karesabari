import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

enum UserRole { farmer, consumer }

enum AppLanguage { ne, en }

enum TrustBadgeType { newSeller, verified }

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    required this.language,
    required this.createdAt,
    required this.email,
    this.photoUrl,
    this.location,
    this.profileCompleted = false,
  });

  final String id;
  final UserRole role;
  final String name;
  final String phone;
  final AppLanguage language;
  final String email;
  final String? photoUrl;
  final String? location;
  final DateTime createdAt;
  final bool profileCompleted;

  AppUser copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? phone,
    AppLanguage? language,
    String? email,
    String? photoUrl,
    String? location,
    DateTime? createdAt,
    bool? profileCompleted,
  }) {
    return AppUser(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'role': role.name,
        'fullName': name,
        'phone': phone,
        'email': email,
        'language': language.name,
        'photo_url': photoUrl,
        'location': location,
        'created_at': timestampToFirestore(createdAt),
        'profileCompleted': profileCompleted,
      };

  Map<String, Object?> toMap() => toFirestore();

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return AppUser.fromMap(data);
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id']! as String,
      role: UserRole.values.byName(map['role']! as String),
      name: (map['fullName'] ?? map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      language: AppLanguage.values.byName(map['language']! as String),
      email: (map['email'] ?? '') as String,
      photoUrl: map['photo_url'] as String?,
      location: map['location'] as String?,
      createdAt: timestampFromFirestoreRequired(map['created_at']),
      profileCompleted: (map['profileCompleted'] ?? false) as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppUser &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            role == other.role &&
            name == other.name &&
            phone == other.phone &&
            language == other.language &&
            email == other.email &&
            photoUrl == other.photoUrl &&
            location == other.location &&
            createdAt == other.createdAt &&
            profileCompleted == other.profileCompleted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        role,
        name,
        phone,
        language,
        email,
        photoUrl,
        location,
        createdAt,
        profileCompleted,
      );
}

class FarmerProfile extends AppUser {
  const FarmerProfile({
    required super.id,
    required super.name,
    required super.phone,
    required super.language,
    required super.createdAt,
    required super.email,
    required this.farmLocation,
    required this.harvestDate,
    required this.trustBadge,
    required this.ordersCompletedCount,
    required this.isPremium,
    super.photoUrl,
    super.profileCompleted,
  }) : super(role: UserRole.farmer, location: farmLocation);

  final String farmLocation;
  final DateTime? harvestDate;
  final TrustBadgeType trustBadge;
  final int ordersCompletedCount;
  final bool isPremium;

  @override
  FarmerProfile copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? phone,
    AppLanguage? language,
    String? email,
    String? photoUrl,
    String? location,
    String? farmLocation,
    DateTime? harvestDate,
    TrustBadgeType? trustBadge,
    int? ordersCompletedCount,
    bool? isPremium,
    DateTime? createdAt,
    bool? profileCompleted,
  }) {
    return FarmerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      farmLocation: farmLocation ?? location ?? this.farmLocation,
      harvestDate: harvestDate ?? this.harvestDate,
      trustBadge: trustBadge ?? this.trustBadge,
      ordersCompletedCount: ordersCompletedCount ?? this.ordersCompletedCount,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  @override
  Map<String, Object?> toFirestore() => {
        ...super.toFirestore(),
        'farm_location': farmLocation,
        'harvest_date': timestampToFirestoreNullable(harvestDate),
        'trust_badge': trustBadge.name,
        'orders_completed_count': ordersCompletedCount,
        'is_premium': isPremium,
      };

  factory FarmerProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return FarmerProfile.fromMap(data);
  }

  factory FarmerProfile.fromMap(Map<String, Object?> map) {
    final base = AppUser.fromMap(map);
    return FarmerProfile(
      id: base.id,
      name: base.name,
      phone: base.phone,
      language: base.language,
      email: base.email,
      photoUrl: base.photoUrl,
      createdAt: base.createdAt,
      profileCompleted: base.profileCompleted,
      farmLocation: (map['farm_location'] ?? base.location ?? '') as String,
      harvestDate: timestampFromFirestore(map['harvest_date']),
      trustBadge: TrustBadgeType.values.byName(
        (map['trust_badge'] ?? TrustBadgeType.newSeller.name) as String,
      ),
      ordersCompletedCount: intFromFirestore(map['orders_completed_count']),
      isPremium: (map['is_premium'] ?? false) as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FarmerProfile &&
            super == other &&
            farmLocation == other.farmLocation &&
            harvestDate == other.harvestDate &&
            trustBadge == other.trustBadge &&
            ordersCompletedCount == other.ordersCompletedCount &&
            isPremium == other.isPremium;
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        farmLocation,
        harvestDate,
        trustBadge,
        ordersCompletedCount,
        isPremium,
      );
}
