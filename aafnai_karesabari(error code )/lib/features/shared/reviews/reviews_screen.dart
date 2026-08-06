import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/review.dart';
import '../../../data/models/order.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/review_service.dart';
import '../../../shared/components/review_input.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Review> _reviews = [];
  Order? _order;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consumerId = FirebaseAuth.instance.currentUser?.uid ?? 'local-consumer';
      final order = await ref.read(orderServiceProvider).getOrderById(widget.orderId);
      if (!mounted) return;
      if (order == null) {
        setState(() {
          _errorMessage = 'Order not found.';
          _isLoading = false;
        });
        return;
      }

      final reviews = await ref.read(reviewServiceProvider).listReviews(orderId: widget.orderId);
      if (!mounted) return;

      setState(() {
        _order = order;
        _reviews = reviews;
        _alreadyReviewed = reviews.any((review) => review.consumerId == consumerId);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview(int rating, String comment) async {
    final consumerId = FirebaseAuth.instance.currentUser?.uid ?? 'local-consumer';
    if (_order == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(reviewServiceProvider).createReview(
            orderId: widget.orderId,
            consumerId: consumerId,
            farmerId: _order!.farmerId,
            rating: rating,
            comment: comment.isEmpty ? null : comment,
          );
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a review')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!, 
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_order != null) ...[
                    Text('Order id: ${_order!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Status: ${_order!.status.name}'),
                    const SizedBox(height: 8),
                    Text('Farmer: ${_order!.farmerId}'),
                    const SizedBox(height: 24),
                    if (!_order!.canBeReviewed)
                      const Text('Reviews are only available for completed orders.'),
                    if (_order!.canBeReviewed && _alreadyReviewed)
                      const Text('You have already left a review for this order.'),
                    if (_order!.canBeReviewed && !_alreadyReviewed)
                      ReviewInput(
                        isLoading: _isSubmitting,
                        onSubmit: _submitReview,
                      ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Order reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _reviews.isEmpty
                        ? const Text('No reviews have been posted for this order yet.')
                        : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              i < review.rating ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (review.comment != null && review.comment!.isNotEmpty)
                                          Text(review.comment!),
                                        const SizedBox(height: 8),
                                        Text('By ${review.consumerId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                        Text('Posted ${review.createdAt.toLocal()}'.split('.').first, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ] else ...[
                    const Center(child: Text('Order data could not be loaded.'))
                  ],
                ],
              ),
            ),
          ),
    );
  }
}
