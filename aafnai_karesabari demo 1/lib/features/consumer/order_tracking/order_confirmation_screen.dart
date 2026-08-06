import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/primary_button.dart';
import '../../../routing/app_routes.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order confirmation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Your order is confirmed!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thank you for shopping local. You can track your orders from the Orders tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'View orders',
              onPressed: () => context.go(AppRoutes.consumerOrders),
            ),
          ],
        ),
      ),
    );
  }
}
