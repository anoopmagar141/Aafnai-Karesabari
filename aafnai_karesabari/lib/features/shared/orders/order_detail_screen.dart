import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/typography.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../data/services/order_service.dart';
import '../../../shared/components/primary_button.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, required this.farmerView});

  final String orderId;
  final bool farmerView;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = true;
  Order? _order;
  String? _listingName;
  String? _personName;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await ref.read(orderServiceProvider).getOrderById(widget.orderId);
    if (order != null) {
      try {
        final listing = await ref.read(listingServiceProvider).getById(order.listingId);
        _listingName = listing?.productName;
      } catch (_) {}
      try {
        final personId = widget.farmerView ? order.consumerId : order.farmerId;
        final person = await FirestoreUserRepository().getById(personId);
        _personName = person?.name;
      } catch (_) {}
    }
    
    if (!mounted) return;
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  Future<void> _cancelOrder() async {
    if (_isProcessing || _order == null) return;
    setState(() => _isProcessing = true);
    await ref.read(orderServiceProvider).updateOrderStatus(_order!.id, OrderStatus.cancelled);
    await _loadOrder();
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.farmerView ? 'Order received' : 'Order details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Order ${_order!.id}', style: AppTypography.screenTitle),
                      const SizedBox(height: 16),
                      Text('Status: ${_order!.status.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text('Product: ${_listingName ?? _order!.listingId}'),
                      const SizedBox(height: 8),
                      Text(widget.farmerView ? 'Consumer: ${_personName ?? _order!.consumerId}' : 'Farmer: ${_personName ?? _order!.farmerId}'),
                      const SizedBox(height: 8),
                      Text('Quantity: ${_order!.quantity.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      Text('Total: NPR ${_order!.totalPrice.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      if (_order!.commissionAmount != null)
                        Text('Commission: NPR ${_order!.commissionAmount!.toStringAsFixed(0)}'),
                      if (_order!.farmerPayout != null)
                        Text('Farmer payout: NPR ${_order!.farmerPayout!.toStringAsFixed(0)}'),
                      const SizedBox(height: 24),
                      if (!widget.farmerView && _order!.canBeCancelled)
                        PrimaryButton(
                          label: 'Cancel order',
                          onPressed: _isProcessing ? null : _cancelOrder,
                        ),
                      if (!widget.farmerView && _order!.canBeReviewed)
                        const SizedBox(height: 12),
                      if (!widget.farmerView && _order!.canBeReviewed)
                        PrimaryButton(
                          label: 'Leave a review',
                          onPressed: _isProcessing
                              ? null
                              : () => context.push('/consumer/orders/${_order!.id}/review'),
                        ),
                    ],
                  ),
                ),
    );
  }
}
