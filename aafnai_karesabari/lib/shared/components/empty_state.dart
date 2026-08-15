import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Standard "nothing here yet" placeholder (icon + title + subtitle)
/// shown wherever a list legitimately has zero items.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 76, color: const Color(0xFF9AB69A)), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted))])));
}
