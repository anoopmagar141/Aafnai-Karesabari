import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/cart_service.dart';

class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.farmer, required this.index, required this.onChanged});

  final bool farmer;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider).value ?? 0;
    final labels = farmer
        ? ['Home', 'Listings', 'Orders', 'Earnings', 'Profile']
        : ['Home', 'Search', 'Wishlist', 'Cart', 'Orders', 'Profile'];
    final icons = farmer
        ? const [
            Icons.home_outlined,
            Icons.inventory_2_outlined,
            Icons.receipt_long_outlined,
            Icons.account_balance_wallet_outlined,
            Icons.person_outline,
          ]
        : const [
            Icons.home_outlined,
            Icons.search,
            Icons.favorite_border,
            Icons.shopping_cart_outlined,
            Icons.receipt_long_outlined,
            Icons.person_outline,
          ];

    final destinations = List.generate(labels.length, (i) {
      final icon = icons[i];
      final widget = i == 3 && !farmer && cartCount > 0
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon),
                Positioned(
                  right: -6,
                  top: -6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : Icon(icon);
      return NavigationDestination(icon: widget, label: labels[i]);
    });

    return NavigationBar(selectedIndex: index, onDestinationSelected: onChanged, destinations: destinations);
  }
}
