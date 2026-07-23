import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget { const OrderCard({super.key, required this.id, required this.product, required this.person, required this.total, required this.pending}); final String id, product, person; final double total; final bool pending; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('$id · Today', style: const TextStyle(color: AppColors.textMuted)), const Spacer(), StatusBadge(label: pending ? 'Pending' : 'Completed', color: pending ? AppColors.accent : AppColors.primary)]), const SizedBox(height: 10), Text(product, style: const TextStyle(fontWeight: FontWeight.w800)), Text(person, style: const TextStyle(color: AppColors.textMuted)), Text(formatNpr(total), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))]))); }
