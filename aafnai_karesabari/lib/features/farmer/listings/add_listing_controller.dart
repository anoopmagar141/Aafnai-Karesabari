import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/listing.dart';

class ListingDraft {
  const ListingDraft({this.step = 0, this.photoUrls = const [], this.productName = '', this.category = ListingCategory.vegetable, this.quantity = 0, this.unit = ListingUnit.kg, this.pricePerUnit});
  final int step;
  final List<String> photoUrls;
  final String productName;
  final ListingCategory category;
  final int quantity;
  final ListingUnit unit;
  final double? pricePerUnit;
  ListingDraft copyWith({int? step, List<String>? photoUrls, String? productName, ListingCategory? category, int? quantity, ListingUnit? unit, double? pricePerUnit}) => ListingDraft(step: step ?? this.step, photoUrls: photoUrls ?? this.photoUrls, productName: productName ?? this.productName, category: category ?? this.category, quantity: quantity ?? this.quantity, unit: unit ?? this.unit, pricePerUnit: pricePerUnit ?? this.pricePerUnit);
}

class ListingDraftNotifier extends StateNotifier<ListingDraft> {
  ListingDraftNotifier() : super(const ListingDraft());
  void setStep(int step) => state = state.copyWith(step: step);
  void updateDetails({required String productName, required ListingCategory category, required int quantity, required ListingUnit unit}) => state = state.copyWith(productName: productName, category: category, quantity: quantity, unit: unit);
  void setPrice(double price) => state = state.copyWith(pricePerUnit: price);
}

final listingDraftProvider = StateNotifierProvider<ListingDraftNotifier, ListingDraft>((ref) => ListingDraftNotifier());
