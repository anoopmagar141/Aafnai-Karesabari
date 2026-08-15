import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../routing/app_routes.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/seller_application_repository.dart';
import '../../../data/models/seller_application.dart';
import '../../../data/services/listing_seed_service.dart';

/// Admin landing page: platform stats and quick-action links to seller
/// verification, user management, catalog seeding, and order oversight.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Settings opens this screen with context.go(), which replaces the
        // nav stack — there's nothing to pop back to, so this needs an
        // explicit way back to the regular buyer/seller app.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to my account',
          onPressed: () {
            context.go(AppRoutes.consumerHome);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              context.push(AppRoutes.editProfile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminProfileCard(onboarding),
            const SizedBox(height: 24),
            const Text('Platform Overview', style: AppTypography.sectionTitle),
            const SizedBox(height: 16),
            _buildStatCards(ref),
            const SizedBox(height: 24),
            const Text('Quick Actions', style: AppTypography.sectionTitle),
            const SizedBox(height: 16),
            _buildQuickActions(context, ref, onboarding),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfileCard(OnboardingController onboarding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withAlpha(50),
              child: const Icon(Icons.admin_panel_settings,
                  size: 30, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin/Developer', style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    onboarding.email ?? 'Unknown Email',
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(WidgetRef ref) {
    return FutureBuilder<List<AppUser>>(
      future: FirestoreUserRepository().list(),
      builder: (context, userSnapshot) {
        final users = userSnapshot.data;
        final usersLabel = users == null ? '…' : '${users.length}';
        final sellersLabel =
            users == null ? '…' : '${users.where((u) => u.sellerStatus == 'approved').length}';

        return Row(
          children: [
            Expanded(
              child: _buildStatCard('Users', usersLabel, Icons.people, Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<SellerApplication>>(
                stream: ref.read(sellerApplicationRepositoryProvider).getPendingApplicationsStream(),
                builder: (context, snapshot) {
                  final label = snapshot.data == null ? '…' : '${snapshot.data!.length}';
                  return _buildStatCard('Pending', label, Icons.assignment_late, Colors.orange);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Sellers', sellersLabel, Icons.storefront, Colors.green),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.screenTitle),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, WidgetRef ref, OnboardingController onboarding) {
    return Column(
      children: [
        _buildActionTile(
          context,
          icon: Icons.verified_user,
          title: 'Seller Verification',
          subtitle: 'Review and approve pending seller applications',
          onTap: () {
            context.push(AppRoutes.adminSellerApplications);
          },
        ),
        _buildActionTile(
          context,
          icon: Icons.group,
          title: 'User Management',
          subtitle: 'View and manage platform users',
          onTap: () {
            context.push(AppRoutes.adminUsers);
          },
        ),
        _buildActionTile(
          context,
          icon: Icons.grass,
          title: 'Seed Sample Listings',
          subtitle: 'Add 50+ demo products (vector icons, no storage used)',
          onTap: () async {
            final adminId = onboarding.uid;
            if (adminId == null) return;
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              const SnackBar(content: Text('Seeding sample listings...')),
            );
            final created = await ref
                .read(listingSeedServiceProvider)
                .seedSampleListings(farmerId: adminId);
            messenger.showSnackBar(
              SnackBar(
                content: Text(created > 0
                    ? 'Added $created new sample listings'
                    : 'Sample listings already seeded'),
              ),
            );
          },
        ),
        _buildActionTile(
          context,
          icon: Icons.receipt_long,
          title: 'All Orders',
          subtitle: 'View and manage every order across all sellers, for dispute handling',
          onTap: () {
            context.push(AppRoutes.adminOrders);
          },
        ),
        _buildActionTile(
          context,
          icon: Icons.storefront_outlined,
          title: 'Manage Seeded Catalog Orders',
          subtitle: 'Accept or reject orders placed against the sample listings',
          onTap: () {
            context.push('/farmer/orders');
          },
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTypography.cardTitle),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
