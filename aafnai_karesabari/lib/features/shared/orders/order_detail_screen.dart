import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId, required this.farmerView});
  final String orderId;
  final bool farmerView;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(farmerView ? 'Order received' : 'Order details')), body: Center(child: Text('Order $orderId\nOrder data will be available after the transaction backend is connected.', textAlign: TextAlign.center)));
}
