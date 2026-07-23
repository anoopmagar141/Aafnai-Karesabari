enum UserRole { farmer, consumer }
enum AppLanguage { ne, en }
enum TrustBadgeType { newSeller, verified }

class AppUser {
  const AppUser({required this.id, required this.role, required this.name, required this.phone, required this.language, required this.createdAt, this.photoUrl});
  final String id;
  final UserRole role;
  final String name;
  final String phone;
  final AppLanguage language;
  final String? photoUrl;
  final DateTime createdAt;
}

class FarmerProfile extends AppUser {
  const FarmerProfile({required super.id, required super.name, required super.phone, required super.language, required super.createdAt, required this.farmLocation, required this.harvestDate, required this.trustBadge, required this.ordersCompletedCount, required this.isPremium, super.photoUrl}) : super(role: UserRole.farmer);
  final String farmLocation;
  final DateTime? harvestDate;
  final TrustBadgeType trustBadge;
  final int ordersCompletedCount;
  final bool isPremium;
}
