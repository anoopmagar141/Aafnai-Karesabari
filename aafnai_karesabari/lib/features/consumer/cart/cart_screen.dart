import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/typography.dart';
import '../../../data/services/cart_service.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/primary_button.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<CartItemSummary> _items = [];
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    final cartService = ref.read(cartServiceProvider);
    final items = await cartService.getCartItems();
    final total = await cartService.getCartTotal();
    if (!mounted) return;

    setState(() {
      _items = items;
      _total = total;
      _isLoading = false;
    });
  }

  Future<void> _updateQuantity(CartItemSummary item, int quantity) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await ref.read(cartServiceProvider).updateQuantity(listingId: item.listing.id, quantity: quantity);
    await ref.read(cartCountProvider.notifier).refreshCartCount();
    await _loadCart();
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _removeItem(CartItemSummary item) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await ref.read(cartServiceProvider).removeItem(item.listing.id);
    await ref.read(cartCountProvider.notifier).refreshCartCount();
    await _loadCart();
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your basket')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_basket_outlined,
                  title: 'Your basket is empty',
                  subtitle: 'Add fresh produce from local farmers.',
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.listing.productName,
                                          style: AppTypography.cardTitle,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _removeItem(item),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (item.entry.offeredPricePerUnit != null) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.local_offer_outlined,
                                            size: 14, color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Your offer: NPR ${item.entry.offeredPricePerUnit!.toStringAsFixed(0)} / ${item.listing.unit.name}',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Listed price: NPR ${item.listing.pricePerUnit.toStringAsFixed(0)} / ${item.listing.unit.name}',
                                      style: const TextStyle(
                                          fontSize: 12, decoration: TextDecoration.lineThrough),
                                    ),
                                  ] else
                                    Text('NPR ${item.listing.pricePerUnit.toStringAsFixed(0)} / ${item.listing.unit.name}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: item.entry.quantity > 1
                                            ? () => _updateQuantity(item, item.entry.quantity - 1)
                                            : null,
                                      ),
                                      Text('${item.entry.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => _updateQuantity(item, item.entry.quantity + 1),
                                      ),
                                      const Spacer(),
                                      Text('NPR ${((item.entry.offeredPricePerUnit ?? item.listing.pricePerUnit) * item.entry.quantity).toStringAsFixed(0)}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text('NPR ${_total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: 'Proceed to checkout',
                            onPressed: _items.isEmpty || _isProcessing
                                ? null
                                : () => context.push(AppRoutes.checkout),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
