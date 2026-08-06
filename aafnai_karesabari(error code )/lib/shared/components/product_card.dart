import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/listing.dart';
import 'status_badge.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.listing, required this.onTap, this.featured = false});
  final Listing listing;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Stack(children: [Container(width: double.infinity, decoration: const BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.vertical(top: Radius.circular(14))), child: Icon(listing.displayIcon, size: 48, color: AppColors.primary)), if (featured) const Positioned(top: 8, left: 8, child: StatusBadge(label: 'Featured', color: AppColors.accent))])),
    Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(listing.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitle), Text('${formatNpr(listing.pricePerUnit)} / ${listing.unit.name}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)), const Row(children: [Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted), Text('Local farm', style: TextStyle(fontSize: 12, color: AppColors.textMuted))])]))
  ])));
}
