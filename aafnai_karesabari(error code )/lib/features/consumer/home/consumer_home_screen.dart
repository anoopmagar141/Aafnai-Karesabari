import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/typography.dart';
import '../../../data/models/listing.dart';
import '../../../data/models/market_price.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../data/repositories/market_price_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../shared/components/category_chip.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/error_state.dart';
import '../../../shared/components/market_price_gauge.dart';
import '../../../shared/components/product_card.dart';
import '../../../shared/components/search_bar.dart';

class ConsumerHomeScreen extends ConsumerStatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  ConsumerState<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends ConsumerState<ConsumerHomeScreen> {
  late final Future<List<Listing>> _listingsFuture;
  late final Future<List<MarketPrice>> _pricesFuture;

  @override
  void initState() {
    super.initState();
    final listingService = ref.read(listingServiceProvider);
    final priceRepository = LocalMarketPriceRepository();
    _listingsFuture = listingService.list(
      filter: const ListingListFilter(limit: 6, status: ListingStatus.active),
    );
    _pricesFuture = priceRepository.list(
      filter: const MarketPriceListFilter(limit: 3),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      final listingService = ref.read(listingServiceProvider);
      final priceRepository = LocalMarketPriceRepository();
      _listingsFuture = listingService.list(
        filter: const ListingListFilter(limit: 6, status: ListingStatus.active),
      );
      _pricesFuture = priceRepository.list(
        filter: const MarketPriceListFilter(limit: 3),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.location_on_outlined),
            SizedBox(width: 4),
            Text('Lalitpur, Nepal'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () => context.push('/consumer/search'),
              child: const AppSearchBar(readOnly: true),
            ),
            const SizedBox(height: 22),
            const Text('Shop by category', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/consumer/search?category=vegetable'),
                    child: const CategoryChip(label: 'Vegetables', icon: Icons.grass),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/consumer/search?category=fruit'),
                    child: const CategoryChip(label: 'Fruits', icon: Icons.apple),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/consumer/search?category=grain'),
                    child: const CategoryChip(label: 'Grains', icon: Icons.egg_alt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Today\'s market prices', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            FutureBuilder<List<MarketPrice>>(
              future: _pricesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const MarketPriceGauge(
                    product: 'Fresh produce',
                    region: 'Lalitpur',
                    hasData: false,
                  );
                }
                final price = snapshot.data!.first;
                return MarketPriceGauge(
                  product: price.productName,
                  region: price.region,
                  hasData: true,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Fresh near you', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            FutureBuilder<List<Listing>>(
              future: _listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    title: 'Could not load listings',
                    message: 'Please try again in a moment.',
                    onRetry: _refresh,
                  );
                }
                final products = snapshot.data ?? const <Listing>[];
                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No fresh produce yet',
                    subtitle: 'Check back soon for new listings from local farmers.',
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (_, index) => ProductCard(
                    listing: products[index],
                    featured: index == 0,
                    onTap: () => context.go('/consumer/product/${products[index].id}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
