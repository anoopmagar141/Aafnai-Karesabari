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
                      onTap: () => context.go('/farmer/listings/${listings[index].id}/edit'),
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
}
