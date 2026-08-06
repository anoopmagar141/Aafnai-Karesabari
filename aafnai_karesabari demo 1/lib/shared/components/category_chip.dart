import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: Chip(avatar: Icon(icon, size: 18, color: AppColors.primary), label: Text(label), backgroundColor: Colors.white, side: const BorderSide(color: AppColors.border)));
}
