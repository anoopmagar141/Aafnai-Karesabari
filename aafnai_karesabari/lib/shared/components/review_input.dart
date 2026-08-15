import 'package:flutter/material.dart';
import 'primary_button.dart';

/// Star-rating + comment input for leaving a review, used by
/// [ReviewsScreen].
class ReviewInput extends StatefulWidget {
  const ReviewInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  final Future<void> Function(int rating, String comment) onSubmit;
  final bool isLoading;

  @override
  State<ReviewInput> createState() => _ReviewInputState();
}

class _ReviewInputState extends State<ReviewInput> {
  int rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating before submitting.')),
      );
      return;
    }

    await widget.onSubmit(rating, _commentController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: widget.isLoading ? null : () => setState(() => rating = i + 1),
              icon: Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
            ),
          ),
        ),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Leave a comment',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: widget.isLoading ? 'Submitting...' : 'Submit review',
          onPressed: widget.isLoading ? null : () {
            _handleSubmit();
          },
        ),
      ],
    );
  }
}
