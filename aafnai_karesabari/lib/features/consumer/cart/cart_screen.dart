import 'package:flutter/material.dart';
import '../../../shared/components/empty_state.dart';

class CartScreen extends StatelessWidget { const CartScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: EmptyState(icon: Icons.shopping_basket_outlined, title: 'Your basket is empty', subtitle: 'Add fresh produce from local farmers.')); }
