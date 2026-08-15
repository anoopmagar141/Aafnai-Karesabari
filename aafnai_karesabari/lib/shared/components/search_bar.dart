import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// The app's search input, used two ways: read-only + `onTap` on Home
/// (taps navigate to Search) or live-filtering with `controller`/
/// `onChanged` on the Search screen itself.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.onChanged,
  });

  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search fresh produce...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller!.clear();
                    onChanged?.call('');
                  },
                )
              : const Icon(Icons.tune),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}
