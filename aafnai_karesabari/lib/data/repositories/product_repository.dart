import 'package:flutter/material.dart';
import '../models/listing.dart';

class ProductRepository {
  const ProductRepository();
  List<Listing> featured() => [
        Listing(id: 'tomatoes', farmerId: 'sita', productName: 'Fresh Tomatoes', category: ListingCategory.vegetable, pricePerUnit: 120, unit: ListingUnit.kg, stockQuantity: 12, status: ListingStatus.active, createdAt: DateTime(2026, 7, 1), displayIcon: Icons.local_florist, isFeatured: true),
        Listing(id: 'spinach', farmerId: 'hari', productName: 'Organic Spinach', category: ListingCategory.vegetable, pricePerUnit: 80, unit: ListingUnit.kg, stockQuantity: 6, status: ListingStatus.active, createdAt: DateTime(2026, 7, 2), displayIcon: Icons.grass),
        Listing(id: 'oranges', farmerId: 'maya', productName: 'Sweet Oranges', category: ListingCategory.fruit, pricePerUnit: 180, unit: ListingUnit.kg, stockQuantity: 20, status: ListingStatus.active, createdAt: DateTime(2026, 7, 3), displayIcon: Icons.circle),
        Listing(id: 'eggs', farmerId: 'laxmi', productName: 'Free-range Eggs', category: ListingCategory.grain, pricePerUnit: 240, unit: ListingUnit.piece, stockQuantity: 18, status: ListingStatus.active, createdAt: DateTime(2026, 7, 4), displayIcon: Icons.egg_alt),
      ];
}
