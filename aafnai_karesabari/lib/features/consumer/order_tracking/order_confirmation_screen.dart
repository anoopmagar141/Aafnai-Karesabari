import 'package:flutter/material.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Order confirmation')), body: const Center(child: Text('No order has been placed yet.', textAlign: TextAlign.center)));
}
