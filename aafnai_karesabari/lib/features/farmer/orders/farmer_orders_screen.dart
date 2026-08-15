import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/order_service.dart';
import 'update_order_status_dialog.dart';

/// Farmer's incoming orders: accept/reject/cancel via [OrderService] (so
/// the buyer's status-change notification always fires) and see any
/// negotiated offer next to the listing's normal price.
class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  List<Order> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final farmerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final orders = await _orderService.listFarmerOrders(farmerId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _successMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Order accepted — the buyer has been notified it\'s on the way.';
      case OrderStatus.rejected:
        return 'Order declined — the buyer has been notified.';
      case OrderStatus.cancelled:
        return 'Order cancelled.';
      case OrderStatus.completed:
        return 'Order marked as delivered.';
      case OrderStatus.pending:
        return 'Order status updated.';
    }
  }

  Future<void> _updateStatus(Order order, OrderStatus newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Goes through OrderService (not the repository directly) so the
      // buyer's status-change notification actually gets created.
      await _orderService.updateOrderStatus(order.id, newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_successMessage(newStatus)),
          duration: const Duration(seconds: 3),
        ),
      );
      await _loadOrders();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: _orders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your customer orders will appear here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) =>
                              _buildOrderCard(context, _orders[index]),
                        ),
                ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final createdDate = dateFormat.format(order.createdAt);
    final createdTime = timeFormat.format(order.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header with ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$createdDate at $createdTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(height: 24),
            // Product Details
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity: ${order.quantity.toStringAsFixed(0)} units',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Listing ID: ${order.listingId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buyer Info
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buyer',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder(
                        future: FirestoreUserRepository().getById(order.consumerId),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.name;
                          return Text(
                            name != null && name.isNotEmpty ? name : 'Buyer ${order.consumerId.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.isNegotiated) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buyer offered Rs ${order.pricePerUnit.toStringAsFixed(0)}/unit',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          Text(
                            'Your listed price: Rs ${order.listingPricePerUnit!.toStringAsFixed(0)}/unit',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Amount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Rs ${order.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Update Status Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) => UpdateOrderStatusDialog(
                      order: order,
                      onStatusUpdate: (newStatus) => _updateStatus(order, newStatus),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Update Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final statusColors = {
      OrderStatus.pending: (Colors.orange, Colors.orange.shade50),
      OrderStatus.accepted: (Colors.blue, Colors.blue.shade50),
      OrderStatus.completed: (Colors.green, Colors.green.shade50),
      OrderStatus.rejected: (Colors.red, Colors.red.shade50),
      OrderStatus.cancelled: (Colors.grey, Colors.grey.shade50),
    };

    final (statusColor, backgroundColor) =
        statusColors[status] ?? (Colors.grey, Colors.grey.shade50);
    final statusLabel = status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: statusColor,
        ),
      ),
    );
  }
}
