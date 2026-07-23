import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, this.onTap, this.readOnly = false});
  final VoidCallback? onTap;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => TextField(readOnly: readOnly, onTap: onTap, decoration: InputDecoration(hintText: 'Search fresh produce...', prefixIcon: const Icon(Icons.search), suffixIcon: const Icon(Icons.tune), filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))));
}
