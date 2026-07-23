import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
class LoadingSkeleton extends StatelessWidget { const LoadingSkeleton({super.key, this.height = 16, this.width = double.infinity}); final double height, width; @override Widget build(BuildContext context) => Container(height: height, width: width, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8))); }
