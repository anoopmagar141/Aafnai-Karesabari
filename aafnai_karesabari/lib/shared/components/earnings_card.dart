import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Farmer earnings summary tile. NOTE: currently renders static
/// placeholder figures ("NPR 18,560") rather than the farmer's real
/// totals — not yet wired to [EarningsScreen]'s actual order data.
class EarningsCard extends StatelessWidget { const EarningsCard({super.key, this.summary = false}); final bool summary; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: summary ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(18)), child: summary ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total earnings', style: TextStyle(color: Colors.white70)), SizedBox(height: 5), Text('NPR 18,560', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)), Text('+ NPR 2,140 this week', style: TextStyle(color: Colors.white70))]) : const Text('Earnings transaction')); }
