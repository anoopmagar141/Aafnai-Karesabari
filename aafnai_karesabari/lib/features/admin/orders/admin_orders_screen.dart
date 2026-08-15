import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../data/services/order_service.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/error_state.dart';
import '../../../shared/components/status_badge.dart';

/// Cross-seller order oversight for admins: every order on the platform,
/// filterable by status, with a force-cancel action for dispute handling.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _statusFilter;
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Order>> _load() {
    return ref.read(orderServiceProvider).listAllOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  (String, Color) _statusDisplay(OrderStatus status) => switch (status) {
        OrderStatus.pending => ('Pending', AppColors.accent),
        OrderStatus.accepted => ('On the way', Colors.blue),
        OrderStatus.completed => ('Delivered', AppColors.primary),
        OrderStatus.rejected => ('Declined', Colors.red),
        OrderStatus.cancelled => ('Cancelled', Colors.grey),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              title: 'Could not load orders',
              message: 'Please try again in a moment.',
              onRetry: _refresh,
            );
          }

          final all = snapshot.data ?? const <Order>[];
          final orders = _statusFilter == null
              ? all
              : all.where((o) => o.status == _statusFilter).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      for (final status in OrderStatus.values) ...[
                        _buildFilterChip(_statusDisplay(status).$1, status),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders found',
                    subtitle: 'Nothing matches this filter yet.',
                  )
                else
                  for (final order in orders) _AdminOrderCard(order: order, onChanged: _refresh),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status) {
    final selected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = status),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textMuted),
    );
  }
}

class _AdminOrderCard extends ConsumerStatefulWidget {
  const _AdminOrderCard({required this.order, required this.onChanged});
  final Order order;
  final VoidCallback onChanged;

  @override
  ConsumerState<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends ConsumerState<_AdminOrderCard> {
  String? _productName;
  String? _buyerName;
  String? _sellerName;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _resolveNames();
  }

  Future<void> _resolveNames() async {
    try {
      final listing = await ref.read(listingServiceProvider).getById(widget.order.listingId);
      if (mounted) setState(() => _productName = listing?.productName);
    } catch (_) {}
    try {
      final buyer = await FirestoreUserRepository().getById(widget.order.consumerId);
      if (mounted) setState(() => _buyerName = buyer?.name);
    } catch (_) {}
    try {
      final seller = await FirestoreUserRepository().getById(widget.order.farmerId);
      if (mounted) setState(() => _sellerName = seller?.name);
    } catch (_) {}
  }

  Future<void> _forceCancel() async {
    setState(() => _updating = true);
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(widget.order.id, OrderStatus.cancelled);
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not cancel this order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  (String, Color) get _statusDisplay => switch (widget.order.status) {
        OrderStatus.pending => ('Pending', AppColors.accent),
        OrderStatus.accepted => ('On the way', Colors.blue),
        OrderStatus.completed => ('Delivered', AppColors.primary),
        OrderStatus.rejected => ('Declined', Colors.red),
        OrderStatus.cancelled => ('Cancelled', Colors.grey),
      };

  bool get _canForceCancel =>
      widget.order.status == OrderStatus.pending || widget.order.status == OrderStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final (label, color) = _statusDisplay;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.id, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                StatusBadge(label: label, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(_productName ?? order.listingId, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Buyer: ${_buyerName ?? order.consumerId}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            Text('Seller: ${_sellerName ?? order.farmerId}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(formatNpr(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                if (order.isNegotiated) ...[
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'Negotiated', color: Colors.deepPurple),
                ],
              ],
            ),
            if (_canForceCancel) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _updating ? null : _forceCancel,
                  icon: const Icon(Icons.block, size: 18, color: Colors.red),
                  label: Text(
                    _updating ? 'Cancelling...' : 'Force cancel',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
