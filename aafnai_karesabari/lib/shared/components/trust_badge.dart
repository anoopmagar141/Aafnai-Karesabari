import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// A small verified-checkmark + label badge, e.g. "42 orders completed"
/// on [FarmerCard].
class TrustBadge extends StatelessWidget { const TrustBadge({super.key, required this.label}); final String label; @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified, color: AppColors.primary, size: 14), const SizedBox(width: 3), Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))]); }
