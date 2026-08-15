import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/listing.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../data/services/listing_service.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/error_state.dart';
import '../../../shared/components/status_badge.dart';
import 'add_listing_controller.dart';
import 'update_inventory_dialog.dart';

/// Farmer's product catalog: their own listings with quick actions to
/// edit, update stock, or add a new one.
class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  String get _farmerId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'local-farmer';

  Future<void> _refreshListings() async {
    ref.invalidate(farmerListingsProvider(_farmerId));
    await ref.read(farmerListingsProvider(_farmerId).future);
  }

  Future<void> _togglePublish(Listing listing) async {
    final service = ref.read(listingServiceProvider);
    try {
      if (listing.status == ListingStatus.active) {
        await service.unpublish(listing.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing unpublished')),
        );
      } else {
        await service.publish(
          data: ListingFormData.fromListing(listing),
          farmerId: listing.farmerId,
          listingId: listing.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing published')),
        );
      }
      await _refreshListings();
    } on ListingValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.result.errors.values.first)),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _deleteListing(Listing listing) async {
    try {
      await ref.read(listingServiceProvider).deleteListing(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted')),
      );
      await _refreshListings();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _updateStock(Listing listing, int newQuantity) async {
    try {
      await ref.read(listingRepositoryProvider).update(
            listing.copyWith(stockQuantity: newQuantity, updatedAt: DateTime.now()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated')),
      );
      await _refreshListings();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _showUpdateStockDialog(Listing listing) {
    showDialog<void>(
      context: context,
      builder: (_) => UpdateInventoryDialog(
        currentQuantity: listing.stockQuantity,
        listingName: listing.productName,
        onUpdate: (newQuantity) => _updateStock(listing, newQuantity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(farmerListingsProvider(_farmerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farmer/listings/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add listing'),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          title: 'Could not load listings',
          message: 'Check your connection and try again.',
          onRetry: _refreshListings,
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return const EmptyState(
              icon: Icons.local_florist_outlined,
              title: 'No listings yet',
              subtitle: 'Create your first listing to start selling produce.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshListings,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final listing = listings[index];
                return _ListingTile(
                  listing: listing,
                  onEdit: () => context.push('/farmer/listings/${listing.id}/edit'),
                  onTogglePublish: () => _togglePublish(listing),
                  onDelete: () => _deleteListing(listing),
                  onUpdateStock: () => _showUpdateStockDialog(listing),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({
    required this.listing,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onDelete,
    required this.onUpdateStock,
  });

  final Listing listing;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;
  final VoidCallback onUpdateStock;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (listing.status) {
      ListingStatus.active => 'Published',
      ListingStatus.draft => 'Draft',
      ListingStatus.soldOut => 'Sold out',
    };
    final statusColor = switch (listing.status) {
      ListingStatus.active => AppColors.primary,
      ListingStatus.draft => AppColors.textMuted,
      ListingStatus.soldOut => AppColors.accent,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(listing.productName, style: AppTypography.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'NPR ${listing.pricePerUnit.toStringAsFixed(0)} / ${listing.unit.name} • ${listing.stockQuantity} in stock',
            ),
            if (listing.location != null) Text(listing.location!),
            const SizedBox(height: 8),
            StatusBadge(label: statusLabel, color: statusColor),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'stock':
                onUpdateStock();
              case 'publish':
                onTogglePublish();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'stock', child: Text('Update stock')),
            PopupMenuItem(
              value: 'publish',
              child: Text(
                listing.status == ListingStatus.active
                    ? 'Unpublish'
                    : 'Publish',
              ),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
