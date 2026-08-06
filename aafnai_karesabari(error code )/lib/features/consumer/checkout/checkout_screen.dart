import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/empty_state.dart';
import '../../../routing/app_routes.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/order_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<CartItemSummary> _items = [];
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCheckout();
  }

  Future<void> _loadCheckout() async {
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

  Future<void> _placeOrder() async {
    if (_items.isEmpty || _isProcessing) return;
    setState(() => _isProcessing = true);
    final consumerId = FirebaseAuth.instance.currentUser?.uid ?? 'local-consumer';
    final entries = _items.map((item) => item.entry).toList(growable: false);
    await ref.read(orderServiceProvider).createOrdersForCart(consumerId, entries);
    await ref.read(cartServiceProvider).clearCart();
    await ref.read(cartCountProvider.notifier).refreshCartCount();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    context.go(AppRoutes.orderConfirmation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_basket_outlined,
                  title: 'No items to checkout',
                  subtitle: 'Add items to your basket first.',
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Order summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              title: Text(item.listing.productName),
                              subtitle: Text('${item.entry.quantity} x NPR ${item.listing.pricePerUnit.toStringAsFixed(0)}'),
                              trailing: Text('NPR ${(item.listing.pricePerUnit * item.entry.quantity).toStringAsFixed(0)}'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Total: NPR ${_total.toStringAsFixed(0)}', style: AppTypography.price.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Place order',
                        onPressed: _isProcessing ? null : _placeOrder,
                      ),
                    ],
                  ),
                ),
    );
  }
}
