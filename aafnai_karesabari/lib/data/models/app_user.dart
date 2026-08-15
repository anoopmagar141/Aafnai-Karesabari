import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/firestore_helpers.dart';

enum AppLanguage { ne, en }

enum TrustBadgeType { newSeller, verified }

/// A platform user's profile: identity, delivery/farm location, and role
/// flags (`isAdmin`, `sellerStatus`) that gate access to the farmer and
/// admin areas of the app.
class AppUser {
  const AppUser({
    // Existing fields...
    required this.id,
    required this.name,
    required this.phone,
    required this.language,
    required this.email,
    this.photoUrl,
    this.location,
    this.municipality,
    this.district,
    this.province,
    this.country,
    this.socialLinks,
    this.bio,
    this.interests,
    this.businessName,
    this.businessLogoUrl,
    this.ownerName,
    this.businessDescription,
    this.farmAddress,
    this.productCategories,
    this.businessHours,
    this.verificationBadge,
    this.sellerRating,
    this.totalReviews,
    this.totalProducts,
    required this.createdAt,
    this.dateOfBirth,
    this.profileCompleted = false,
    this.isAdmin = false,
    this.activeRole = 'buyer',
    this.sellerStatus = 'none',
    this.harvestDate,
    this.trustBadge = TrustBadgeType.newSeller,
    this.ordersCompletedCount = 0,
    this.isPremium = false,
    this.wishlist = const [],
  });

  final String id;
  final String name;
  final String phone;
  final AppLanguage language;
  final String email;
  final String? photoUrl;
  final String? location;
  final String? municipality;
  final String? district;
  final String? province;
  final String? country;
  final Map<String, String>? socialLinks;
  final String? bio;
  final List<String>? interests;
  final String? businessName;
  final String? businessLogoUrl;
  final String? ownerName;
  final String? businessDescription;
  final String? farmAddress;
  final List<String>? productCategories;
  final String? businessHours;
  /// List of listing IDs the user has added to their wishlist
  final List<String> wishlist;
  final String? verificationBadge;
  final double? sellerRating;
  final int? totalReviews;
  final int? totalProducts;
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final bool profileCompleted;
  
  // Role & Admin fields
  final bool isAdmin;
  final String activeRole; // e.g. "buyer" or "seller"
  final String sellerStatus; // "none", "pending", "approved", "rejected"
  
  // Computed seller flags to maintain backward compatibility
  bool get isSeller => sellerStatus != 'none';
  bool get sellerVerified => sellerStatus == 'approved';

  // Seller specific fields
  final DateTime? harvestDate;
  final TrustBadgeType trustBadge;
  final int ordersCompletedCount;
  final bool isPremium;

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    AppLanguage? language,
    String? email,
    String? photoUrl,
    String? location,
    String? municipality,
    String? district,
    String? province,
    String? country,
    Map<String, String>? socialLinks,
    String? bio,
    List<String>? interests,
    String? businessName,
    String? businessLogoUrl,
    String? ownerName,
    String? businessDescription,
    String? farmAddress,
    List<String>? productCategories,
    String? businessHours,
    String? verificationBadge,
    double? sellerRating,
    int? totalReviews,
    int? totalProducts,
    DateTime? createdAt,
    DateTime? dateOfBirth,
    bool? profileCompleted,
    bool? isAdmin,
    String? activeRole,
    String? sellerStatus,
    DateTime? harvestDate,
    TrustBadgeType? trustBadge,
    int? ordersCompletedCount,
    bool? isPremium,
    List<String>? wishlist,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      municipality: municipality ?? this.municipality,
      district: district ?? this.district,
      province: province ?? this.province,
      country: country ?? this.country,
      socialLinks: socialLinks ?? this.socialLinks,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      businessName: businessName ?? this.businessName,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      ownerName: ownerName ?? this.ownerName,
      businessDescription: businessDescription ?? this.businessDescription,
      farmAddress: farmAddress ?? this.farmAddress,
      productCategories: productCategories ?? this.productCategories,
      businessHours: businessHours ?? this.businessHours,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      sellerRating: sellerRating ?? this.sellerRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalProducts: totalProducts ?? this.totalProducts,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isAdmin: isAdmin ?? this.isAdmin,
      activeRole: activeRole ?? this.activeRole,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      harvestDate: harvestDate ?? this.harvestDate,
      trustBadge: trustBadge ?? this.trustBadge,
      ordersCompletedCount: ordersCompletedCount ?? this.ordersCompletedCount,
      isPremium: isPremium ?? this.isPremium,
      wishlist: wishlist ?? this.wishlist,
    );
  }

  Map<String, Object?> toFirestore() => {
        'id': id,
        'fullName': name,
        'phone': phone,
        'email': email,
        'language': language.name,
        'photo_url': photoUrl,
        'location': location,
        'municipality': municipality,
        'district': district,
        'province': province,
        'country': country,
        'social_links': socialLinks,
        'bio': bio,
        'interests': interests,
        'business_name': businessName,
        'business_logo_url': businessLogoUrl,
        'owner_name': ownerName,
        'business_description': businessDescription,
        'farm_address': farmAddress,
        'product_categories': productCategories,
        'business_hours': businessHours,
        'verification_badge': verificationBadge,
        'seller_rating': sellerRating,
        'total_reviews': totalReviews,
        'total_products': totalProducts,
        'created_at': timestampToFirestore(createdAt),
        'date_of_birth': timestampToFirestoreNullable(dateOfBirth),
        'profileCompleted': profileCompleted,
        'isAdmin': isAdmin,
        'activeRole': activeRole,
        'sellerStatus': sellerStatus,
        'harvest_date': timestampToFirestoreNullable(harvestDate),
        'trust_badge': trustBadge.name,
        'orders_completed_count': ordersCompletedCount,
        'is_premium': isPremium,
        'wishlist': wishlist,
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
      name: (map['fullName'] ?? map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      language: AppLanguage.values.byName(map['language']! as String),
      email: (map['email'] ?? '') as String,
      photoUrl: map['photo_url'] as String?,
      location: (map['location'] ?? map['farm_location']) as String?,
      municipality: map['municipality'] as String?,
      district: map['district'] as String?,
      province: map['province'] as String?,
      country: map['country'] as String?,
      socialLinks: (map['social_links'] as Map?)?.cast<String, String>(),
      bio: map['bio'] as String?,
      interests: (map['interests'] as List?)?.cast<String>(),
      businessName: map['business_name'] as String?,
      businessLogoUrl: map['business_logo_url'] as String?,
      ownerName: map['owner_name'] as String?,
      businessDescription: map['business_description'] as String?,
      farmAddress: map['farm_address'] as String?,
      productCategories: (map['product_categories'] as List?)?.cast<String>(),
      businessHours: map['business_hours'] as String?,
      wishlist: (map['wishlist'] as List?)?.cast<String>() ?? const [],
      verificationBadge: map['verification_badge'] as String?,
      sellerRating: (map['seller_rating'] as num?)?.toDouble(),
      totalReviews: map['total_reviews'] as int?,
      totalProducts: map['total_products'] as int?,
      createdAt: timestampFromFirestoreRequired(map['created_at']),
      dateOfBirth: timestampFromFirestore(map['date_of_birth']),
      profileCompleted: (map['profileCompleted'] ?? false) as bool,
      isAdmin: (map['isAdmin'] ?? false) as bool,
      activeRole: (map['activeRole'] ?? 'buyer') as String,
      sellerStatus: _parseSellerStatus(map),
      harvestDate: timestampFromFirestore(map['harvest_date']),
      trustBadge: TrustBadgeType.values.byName(
        (map['trust_badge'] ?? TrustBadgeType.newSeller.name) as String,
      ),
      ordersCompletedCount: intFromFirestore(map['orders_completed_count']),
      isPremium: (map['is_premium'] ?? false) as bool,
    );
  }

  static String _parseSellerStatus(Map<String, Object?> map) {
    if (map['sellerStatus'] != null) {
      return map['sellerStatus']! as String;
    }
    // Fallback for old documents
    final bool oldVerified = (map['sellerVerified'] ?? map['role'] == 'farmer') as bool;
    final bool oldIsSeller = (map['isSeller'] ?? map['role'] == 'farmer') as bool;
    if (oldVerified) return 'approved';
    if (oldIsSeller) return 'pending';
    return 'none';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppUser &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            phone == other.phone &&
            language == other.language &&
            email == other.email &&
            photoUrl == other.photoUrl &&
            location == other.location &&
            createdAt == other.createdAt &&
            dateOfBirth == other.dateOfBirth &&
            profileCompleted == other.profileCompleted &&
            isAdmin == other.isAdmin &&
            activeRole == other.activeRole &&
            sellerStatus == other.sellerStatus &&
            harvestDate == other.harvestDate &&
            trustBadge == other.trustBadge &&
            ordersCompletedCount == other.ordersCompletedCount &&
            isPremium == other.isPremium;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        phone,
        language,
        email,
        photoUrl,
        location,
        createdAt,
        dateOfBirth,
        profileCompleted,
        isAdmin,
        activeRole,
        sellerStatus,
        harvestDate,
        trustBadge,
        ordersCompletedCount,
        isPremium,
      );
}
