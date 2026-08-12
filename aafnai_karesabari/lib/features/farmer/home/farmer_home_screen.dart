import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/listing.dart';
import '../../../data/models/order.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../data/services/order_service.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/earnings_card.dart';
import '../../../shared/components/order_card.dart';
import '../../../shared/components/product_card.dart';

class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  late final Future<List<Listing>> _listingsFuture;
  late final Future<List<Order>> _ordersFuture;
  late final Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    final farmerId = FirebaseAuth.instance.currentUser?.uid ?? 'local-farmer';
    _listingsFuture = ref.read(listingServiceProvider).listForFarmer(farmerId);
    _ordersFuture = ref.read(orderServiceProvider).listFarmerOrders(farmerId);
    _userFuture = FirestoreUserRepository().getById(farmerId).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.consumerHome),
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch to buyer view',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<AppUser?>(
            future: _userFuture,
            builder: (context, snapshot) {
              final name = snapshot.data?.name ?? 'Farmer';
              return Text('Namaste, $name!', style: AppTypography.screenTitle);
            }
          ),
          const Text('Here\'s your farm at a glance.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          const EarningsCard(summary: true),
          const SizedBox(height: 24),
          Text('Quick actions', style: AppTypography.sectionTitle),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildQuickAction(
                icon: Icons.list_alt,
                label: 'Listings',
                onPressed: () => context.go('/farmer/listings'),
              ),
              _buildQuickAction(
                icon: Icons.shopping_bag,
                label: 'Orders',
                onPressed: () => context.go('/farmer/orders'),
              ),
              _buildQuickAction(
                icon: Icons.trending_up,
                label: 'Earnings',
                onPressed: () => context.go('/farmer/earnings'),
              ),
              _buildQuickAction(
                icon: Icons.person,
                label: 'Profile',
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Listing>>(
            future: _listingsFuture,
            builder: (context, snapshot) {
              final listings = snapshot.data ?? const [];
              final activeCount =
                  listings.where((l) => l.status == ListingStatus.active).length;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Listings',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeCount.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('My listings', style: AppTypography.sectionTitle),
          FutureBuilder<List<Listing>>(
            future: _listingsFuture,
            builder: (context, snapshot) {
              final listings = snapshot.data ?? const [];
              if (listings.isEmpty) return const Text('No listings yet.');
              return SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => SizedBox(
                    width: 165,
                    child: ProductCard(
                      listing: listings[index],
                      onTap: () => context.push('/farmer/listings/${listings[index].id}/edit'),
                    ),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 20),
          const Text('Recent orders', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          FutureBuilder<List<Order>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const [];
              if (orders.isEmpty) return const Text('No orders yet.');
              final order = orders.first;
              return OrderCardResolver(
                order: order,
                farmerView: true,
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
