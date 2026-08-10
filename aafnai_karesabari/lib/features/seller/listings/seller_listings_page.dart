import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/seller_listing.dart';
import '../../../data/repositories/seller_listing_repository.dart';
import '../../../routing/app_routes.dart';
import 'update_inventory_dialog.dart';

class SellerListingsPage extends ConsumerWidget {
  const SellerListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final repo = SellerListingRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Your Listings')),
      body: StreamBuilder<List<SellerListing>>(
        stream: repo.streamBySeller(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data ?? [];
          if (listings.isEmpty) {
            return const Center(child: Text('No listings yet.'));
          }
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final list = listings[index];
              return ListTile(
                title: Text(list.productName),
                subtitle: Text(
                  '\${list.price.toStringAsFixed(2)} | Stock: ${list.quantity}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.go(AppRoutes.sellerListingsEdit.replaceFirst(':id', list.id));
                    } else if (value == 'inventory') {
                      await showDialog<void>(
                        context: context,
                        builder: (context) => UpdateInventoryDialog(
                          currentQuantity: list.quantity,
                          listingName: list.productName,
                          onUpdate: (newQuantity) async {
                            try {
                              final updated = list.copyWith(quantity: newQuantity);
                              await repo.update(updated);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Stock updated successfully'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete listing'),
                          content: const Text('Are you sure you want to delete this listing?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await repo.delete(list.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'inventory',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, size: 18),
                          SizedBox(width: 8),
                          Text('Update Stock'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Add Listing'),
        icon: const Icon(Icons.add),
        onPressed: () => context.go(AppRoutes.sellerListingsCreate),
      ),
    );
  }
}
