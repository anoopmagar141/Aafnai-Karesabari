import 'package:flutter/material.dart';

/// Dialog for a farmer to quickly adjust a listing's stock quantity
/// without opening the full edit form.
class UpdateInventoryDialog extends StatefulWidget {
  final int currentQuantity;
  final String listingName;
  final VoidCallback? onCancel;
  final Function(int newQuantity) onUpdate;

  const UpdateInventoryDialog({
    super.key,
    required this.currentQuantity,
    required this.listingName,
    required this.onUpdate,
    this.onCancel,
  });

  @override
  State<UpdateInventoryDialog> createState() => _UpdateInventoryDialogState();
}

class _UpdateInventoryDialogState extends State<UpdateInventoryDialog> {
  late TextEditingController _quantityController;
  late int _newQuantity;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newQuantity = widget.currentQuantity;
    _quantityController = TextEditingController(
      text: widget.currentQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _validateAndUpdate() {
    final input = _quantityController.text.trim();

    if (input.isEmpty) {
      setState(() => _error = 'Quantity cannot be empty');
      return;
    }

    final parsed = int.tryParse(input);
    if (parsed == null) {
      setState(() => _error = 'Please enter a valid number');
      return;
    }

    if (parsed < 0) {
      setState(() => _error = 'Quantity cannot be negative');
      return;
    }

    widget.onUpdate(parsed);
    Navigator.of(context).pop();
  }

  void _adjustQuantity(int delta) {
    final newValue = _newQuantity + delta;
    if (newValue >= 0) {
      setState(() {
        _newQuantity = newValue;
        _quantityController.text = newValue.toString();
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stock for ${widget.listingName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current quantity display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Stock:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${widget.currentQuantity} units',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quantity input with +/- buttons
          const Text(
            'New Quantity',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim());
                    if (parsed != null && parsed >= 0) {
                      setState(() {
                        _newQuantity = parsed;
                        _error = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter new quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick adjust buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAdjustButton('-10', () => _adjustQuantity(-10)),
              _buildAdjustButton('-1', () => _adjustQuantity(-1)),
              _buildAdjustButton('+1', () => _adjustQuantity(1)),
              _buildAdjustButton('+10', () => _adjustQuantity(10)),
            ],
          ),

          const SizedBox(height: 16),

          // Info message
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set to 0 to mark as out of stock',
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
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndUpdate,
          child: const Text('Update Stock'),
        ),
      ],
    );
  }

  Widget _buildAdjustButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
