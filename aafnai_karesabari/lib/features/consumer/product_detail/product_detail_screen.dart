import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/farmer_card.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/status_badge.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;
  @override Widget build(BuildContext context) {
    final listing = const ProductRepository().featured().firstWhere((item) => item.id == productId, orElse: () => const ProductRepository().featured().first);
    return Scaffold(appBar: AppBar(), body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Expanded(child: ListView(children: [Container(height: 250, decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(20)), child: Icon(listing.displayIcon, size: 100, color: AppColors.primary)), const SizedBox(height: 20), Text(listing.productName, style: AppTypography.screenTitle), Text('NPR ${listing.pricePerUnit.toStringAsFixed(0)} / ${listing.unit.name}', style: AppTypography.price.copyWith(color: AppColors.primary)), const SizedBox(height: 10), const StatusBadge(label: 'In stock', color: AppColors.primary), const SizedBox(height: 24), const FarmerCard(name: 'Local farmer', district: 'Lalitpur')])), PrimaryButton(label: 'Add to basket', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to your basket'))); context.go(AppRoutes.cart); })])));
  }
}
