import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/typography.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/category_chip.dart';
import '../../../shared/components/product_card.dart';
import '../../../shared/components/search_bar.dart';

class ConsumerHomeScreen extends StatelessWidget {
  const ConsumerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final products = const ProductRepository().featured();
    return Scaffold(appBar: AppBar(title: const Row(children: [Icon(Icons.location_on), SizedBox(width: 4), Text('Lalitpur, Nepal')])), body: ListView(padding: const EdgeInsets.all(16), children: [AppSearchBar(readOnly: true, onTap: () {}), const SizedBox(height: 22), const Text('Shop by category', style: AppTypography.sectionTitle), const SizedBox(height: 10), const SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [CategoryChip(label: 'Vegetables', icon: Icons.grass), CategoryChip(label: 'Fruits', icon: Icons.apple), CategoryChip(label: 'Dairy', icon: Icons.egg_alt), CategoryChip(label: 'Herbs', icon: Icons.spa)])), const SizedBox(height: 24), const Text('Fresh near you', style: AppTypography.sectionTitle), const SizedBox(height: 12), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: products.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 220, crossAxisSpacing: 12, mainAxisSpacing: 12), itemBuilder: (_, index) => ProductCard(listing: products[index], featured: index == 0, onTap: () => context.go('/consumer/product/${products[index].id}')))]));
  }
}
