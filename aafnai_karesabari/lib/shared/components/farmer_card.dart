import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'trust_badge.dart';

/// A compact farmer summary row (name, district) shown on the product
/// detail page. NOTE: the "42 orders completed" trust badge is a static
/// placeholder, not the farmer's real completed-order count.
class FarmerCard extends StatelessWidget {
  const FarmerCard({super.key, required this.name, required this.district});
  final String name, district;
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AppColors.softGreen, child: Icon(Icons.person, color: AppColors.primary)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(district), const TrustBadge(label: '42 orders completed')]), trailing: const Icon(Icons.chevron_right)));
}
