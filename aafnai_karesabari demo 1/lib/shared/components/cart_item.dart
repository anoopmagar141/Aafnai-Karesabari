import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../data/models/listing.dart';
class CartItem extends StatelessWidget { const CartItem({super.key, required this.listing, required this.quantity}); final Listing listing; final int quantity; @override Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.softGreen, child: Icon(listing.displayIcon, color: AppColors.primary)), title: Text(listing.productName), subtitle: Text('NPR ${listing.pricePerUnit.toStringAsFixed(0)} / ${listing.unit.name}'), trailing: Text('$quantity ${listing.unit.name}'))); }
