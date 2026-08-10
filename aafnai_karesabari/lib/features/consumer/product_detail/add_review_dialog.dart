import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/review_service.dart';

class AddReviewDialog extends ConsumerStatefulWidget {
  final String farmerId;
  final VoidCallback onReviewAdded;

  const AddReviewDialog({
    super.key,
    required this.farmerId,
    required this.onReviewAdded,
  });

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  late Future<List<Order>> _ordersFuture;
  int _selectedRating = 5;
  String _comment = '';
  Order? _selectedOrder;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _ordersFuture = _loadCompletedOrders(userId);
  }

  Future<List<Order>> _loadCompletedOrders(String consumerId) async {
    final orderRepo = FirestoreOrderRepository();
    final allOrders = await orderRepo.list(
      filter: OrderListFilter(consumerId: consumerId),
    );
    return allOrders
        .where((o) =>
            o.farmerId == widget.farmerId &&
            o.status == OrderStatus.completed)
        .toList();
  }

  Future<void> _submitReview() async {
    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an order')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final consumerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await ref.read(reviewServiceProvider).createReview(
            orderId: _selectedOrder!.id,
            consumerId: consumerId,
            farmerId: widget.farmerId,
            rating: _selectedRating,
            comment: _comment.isNotEmpty ? _comment : null,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: CircularProgressIndicator(),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return AlertDialog(
            title: const Text('No eligible orders'),
            content: const Text(
              'You can only review after receiving completed orders from this seller.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Add a review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order selector
                const Text(
                  'Select order',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButton<Order>(
                  isExpanded: true,
                  value: _selectedOrder,
                  hint: const Text('Choose an order'),
                  items: orders
                      .map((order) => DropdownMenuItem(
                            value: order,
                            child: Text('Order #${order.id.substring(0, 8)}'),
                          ))
                      .toList(),
                  onChanged: (order) => setState(() => _selectedOrder = order),
                ),
                const SizedBox(height: 20),

                // Rating selector
                const Text(
                  'Rating',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () => setState(() => _selectedRating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < _selectedRating ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comment
                const Text(
                  'Comment (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (value) => _comment = value,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '${_comment.length}/500',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
