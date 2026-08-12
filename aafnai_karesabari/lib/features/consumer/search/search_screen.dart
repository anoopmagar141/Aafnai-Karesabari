import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/listing.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../shared/components/category_chip.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/error_state.dart';
import '../../../shared/components/product_card.dart';
import '../../../shared/components/search_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory});
  final ListingCategory? initialCategory;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  ListingCategory? _selectedCategory;
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _future = _loadListings();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Listing>> _loadListings() {
    // Same real data source as Home — searching against the local fallback
    // repository directly would show demo listings tied to farmer IDs that
    // don't correspond to any real seller, so orders placed against them
    // could never be accepted by anyone.
    return ref.read(listingServiceProvider).list(
          filter: const ListingListFilter(status: ListingStatus.active, limit: 50),
        );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadListings();
    });
  }

  List<Listing> _filterListings(List<Listing> listings) {
    final query = _controller.text.trim().toLowerCase();
    return listings.where((listing) {
      final matchesQuery = query.isEmpty ||
          listing.productName.toLowerCase().contains(query) ||
          (listing.description?.toLowerCase().contains(query) ?? false);
      final matchesCategory = _selectedCategory == null ||
          listing.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search produce')),
      body: FutureBuilder<List<Listing>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              title: 'Could not search listings',
              message: 'Please try again in a moment.',
              onRetry: _refresh,
            );
          }

          final listings = _filterListings(snapshot.data ?? const <Listing>[]);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppSearchBar(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedCategory = null),
                        child: const CategoryChip(label: 'All', icon: Icons.apps),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedCategory = ListingCategory.vegetable),
                        child: const CategoryChip(label: 'Vegetables', icon: Icons.grass),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedCategory = ListingCategory.fruit),
                        child: const CategoryChip(label: 'Fruits', icon: Icons.apple),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedCategory = ListingCategory.grain),
                        child: const CategoryChip(label: 'Grains', icon: Icons.egg_alt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (listings.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No matches found',
                    subtitle: 'Try a different product name or category.',
                  )
                else
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
                      onTap: () => context.go('/consumer/product/${listings[index].id}'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
