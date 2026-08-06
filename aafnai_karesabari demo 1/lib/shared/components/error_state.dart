import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'primary_button.dart';
class ErrorState extends StatelessWidget { const ErrorState({super.key, required this.title, required this.message, this.onRetry}); final String title, message; final VoidCallback? onRetry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: AppColors.accent, size: 64), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), PrimaryButton(label: 'Retry', onPressed: onRetry)]))); }
