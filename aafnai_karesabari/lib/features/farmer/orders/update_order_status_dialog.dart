import 'package:flutter/material.dart';
import '../../../data/models/order.dart';

class UpdateOrderStatusDialog extends StatefulWidget {
  final Order order;
  final Function(OrderStatus newStatus) onStatusUpdate;

  const UpdateOrderStatusDialog({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  State<UpdateOrderStatusDialog> createState() =>
      _UpdateOrderStatusDialogState();
}

class _UpdateOrderStatusDialogState extends State<UpdateOrderStatusDialog> {
  late OrderStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  List<OrderStatus> _getAvailableStatusTransitions() {
    final current = widget.order.status;

    switch (current) {
      case OrderStatus.pending:
        return [
          OrderStatus.pending,
          OrderStatus.accepted,
          OrderStatus.rejected,
        ];
      case OrderStatus.accepted:
        // Completion is confirmed by the buyer once they've received the
        // order, not set by the seller — see the buyer's order detail
        // screen for the "I've received my order" action.
        return [
          OrderStatus.accepted,
          OrderStatus.cancelled,
        ];
      case OrderStatus.completed:
        return [OrderStatus.completed];
      case OrderStatus.rejected:
        return [OrderStatus.rejected];
      case OrderStatus.cancelled:
        return [OrderStatus.cancelled];
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Awaiting your response';
      case OrderStatus.accepted:
        return 'Accepted — the buyer will be told their order is on the way';
      case OrderStatus.completed:
        return 'Order has been delivered';
      case OrderStatus.rejected:
        return 'You have rejected this order';
      case OrderStatus.cancelled:
        return 'Order has been cancelled';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStatuses = _getAvailableStatusTransitions();

    return AlertDialog(
      title: const Text('Update Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current: ${widget.order.status.name.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(widget.order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Available Status Options
          const Text(
            'Select New Status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<OrderStatus>(
            groupValue: _selectedStatus,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
            child: Column(
              children: availableStatuses
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedStatus = status),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedStatus == status
                                  ? _getStatusColor(status)
                                  : Colors.grey.shade300,
                              width: _selectedStatus == status ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _selectedStatus == status
                                ? _getStatusColor(status).withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Radio<OrderStatus>(
                                value: status,
                                activeColor: _getStatusColor(status),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      status.name.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getStatusDescription(status),
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
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Info box
          if (_selectedStatus != widget.order.status)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This change cannot be undone',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedStatus == widget.order.status
              ? null
              : () {
                  widget.onStatusUpdate(_selectedStatus);
                  Navigator.pop(context);
                },
          child: const Text('Update Status'),
        ),
      ],
    );
  }
}
