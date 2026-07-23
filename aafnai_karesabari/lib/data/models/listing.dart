import 'package:flutter/material.dart';

enum ListingCategory { vegetable, fruit, grain }
enum ListingUnit { kg, piece }
enum ListingStatus { active, soldOut, draft }

class Listing {
  const Listing({required this.id, required this.farmerId, required this.productName, required this.category, required this.pricePerUnit, required this.unit, required this.stockQuantity, required this.status, required this.createdAt, this.photoUrls = const [], this.isFeatured = false, this.featuredExpiry, this.displayIcon = Icons.local_florist});
  final String id;
  final String farmerId;
  final String productName;
  final ListingCategory category;
  final double pricePerUnit;
  final ListingUnit unit;
  final int stockQuantity;
  final List<String> photoUrls;
  final ListingStatus status;
  final bool isFeatured;
  final DateTime? featuredExpiry;
  final DateTime createdAt;
  /// Prototype-only fallback when no Storage image exists yet.
  final IconData displayIcon;
}
