import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/listing.dart';
import '../../../data/services/listing_service.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/product_card.dart';

class FarmerProfileScreen extends ConsumerStatefulWidget {
  const FarmerProfileScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  ConsumerState<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends ConsumerState<FarmerProfileScreen> {
  late final Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = ref.read(listingServiceProvider).listForFarmer(widget.farmerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer profile')),
      body: FutureBuilder<List<Listing>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data ?? const <Listing>[];
          if (listings.isEmpty) {
            return const EmptyState(
              icon: Icons.person_outline,
              title: 'Farmer has no listings yet',
              subtitle: 'Please check back later for fresh produce.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local farmer', style: AppTypography.sectionTitle),
                      SizedBox(height: 8),
                      Text(
                        'Fresh produce delivered directly from nearby farms in Lalitpur.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColors.accent, size: 18),
                          SizedBox(width: 4),
                          Text('4.9 • 120 reviews'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Fresh picks', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) => ProductCard(
                  listing: listings[index],
                  onTap: () => context.push('/consumer/product/${listings[index].id}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
