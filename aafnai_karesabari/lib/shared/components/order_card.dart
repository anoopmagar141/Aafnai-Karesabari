import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/listing_service.dart';
import 'status_badge.dart';

class OrderCardResolver extends ConsumerStatefulWidget {
  const OrderCardResolver({super.key, required this.order, this.farmerView = false});
  final Order order;
  final bool farmerView;
  @override
  ConsumerState<OrderCardResolver> createState() => _OrderCardResolverState();
}

class _OrderCardResolverState extends ConsumerState<OrderCardResolver> {
  String? _productName;
  String? _personName;

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
      final personId = widget.farmerView ? widget.order.consumerId : widget.order.farmerId;
      final person = await FirestoreUserRepository().getById(personId);
      if (mounted) setState(() => _personName = person?.name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return OrderCard(
      id: widget.order.id,
      product: _productName ?? widget.order.listingId,
      person: _personName ?? (widget.farmerView ? 'Consumer ${widget.order.consumerId}' : 'Farmer ${widget.order.farmerId}'),
      total: widget.order.totalPrice,
      pending: widget.order.status == OrderStatus.pending,
    );
  }
}

class OrderCard extends StatelessWidget { const OrderCard({super.key, required this.id, required this.product, required this.person, required this.total, required this.pending}); final String id, product, person; final double total; final bool pending; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('$id · Today', style: const TextStyle(color: AppColors.textMuted)), const Spacer(), StatusBadge(label: pending ? 'Pending' : 'Completed', color: pending ? AppColors.accent : AppColors.primary)]), const SizedBox(height: 10), Text(product, style: const TextStyle(fontWeight: FontWeight.w800)), Text(person, style: const TextStyle(color: AppColors.textMuted)), Text(formatNpr(total), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))]))); }
