import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class MarketPriceGauge extends StatelessWidget {
  const MarketPriceGauge({
    super.key,
    required this.product,
    required this.region,
    this.hasData = true,
  });

  final String product;
  final String region;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.textMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No recent market data for this product in your region',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market price for $product in $region',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low\nNPR 90'),
                Text('Average\nNPR 120', textAlign: TextAlign.center),
                Text('High\nNPR 160', textAlign: TextAlign.right),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
