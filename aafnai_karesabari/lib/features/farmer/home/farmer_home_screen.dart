import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/earnings_card.dart';
import '../../../shared/components/order_card.dart';
import '../../../shared/components/product_card.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = const ProductRepository().featured();
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
          const Text('Namaste, Sita!', style: AppTypography.screenTitle),
          const Text('Here\'s your farm at a glance.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          const EarningsCard(summary: true),
          const SizedBox(height: 24),
          const Text('My listings', style: AppTypography.sectionTitle),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => SizedBox(
                width: 165,
                child: ProductCard(listing: products[index], onTap: () {}),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Recent orders', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          const OrderCard(id: '#HK-2048', product: 'Fresh Tomatoes - 2 kg', person: 'Anisha Shrestha', total: 240, pending: true),
        ],
      ),
    );
  }
}
