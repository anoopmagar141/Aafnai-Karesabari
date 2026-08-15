import 'package:flutter/material.dart';

import '../../data/models/listing.dart';

/// Picks a Material vector icon to represent a listing's product, so
/// every listing has visual identity without uploading a photo.
///
/// Maps a listing to a representative icon based on its product name and
/// category. No image assets or Storage uploads involved, which keeps the
/// app within the Firebase free-tier storage quota.
IconData iconForListing(String productName, ListingCategory category) {
  final name = productName.toLowerCase();

  for (final entry in _keywordIcons.entries) {
    if (name.contains(entry.key)) return entry.value;
  }

  switch (category) {
    case ListingCategory.vegetable:
      return Icons.grass;
    case ListingCategory.fruit:
      return Icons.apple;
    case ListingCategory.grain:
      return Icons.grain;
  }
}

const Map<String, IconData> _keywordIcons = {
  'tomato': Icons.local_florist,
  'potato': Icons.eco,
  'onion': Icons.eco,
  'garlic': Icons.eco,
  'ginger': Icons.eco,
  'radish': Icons.eco,
  'carrot': Icons.eco,
  'spinach': Icons.grass,
  'mustard green': Icons.grass,
  'coriander': Icons.grass,
  'cabbage': Icons.grass,
  'cauliflower': Icons.grass,
  'broccoli': Icons.grass,
  'bean': Icons.grass,
  'pea': Icons.grass,
  'okra': Icons.grass,
  'brinjal': Icons.grass,
  'eggplant': Icons.grass,
  'capsicum': Icons.grass,
  'chili': Icons.grass,
  'cucumber': Icons.grass,
  'pumpkin': Icons.grass,
  'gourd': Icons.grass,
  'apple': Icons.apple,
  'mango': Icons.apple,
  'banana': Icons.apple,
  'orange': Icons.apple,
  'guava': Icons.apple,
  'pomegranate': Icons.apple,
  'watermelon': Icons.apple,
  'papaya': Icons.apple,
  'lychee': Icons.apple,
  'pineapple': Icons.apple,
  'grape': Icons.apple,
  'pear': Icons.apple,
  'lemon': Icons.apple,
  'avocado': Icons.apple,
  'kiwi': Icons.apple,
  'coconut': Icons.apple,
  'rice': Icons.grain,
  'wheat': Icons.grain,
  'flour': Icons.grain,
  'maize': Icons.grain,
  'corn': Icons.grain,
  'millet': Icons.grain,
  'buckwheat': Icons.grain,
  'barley': Icons.grain,
  'lentil': Icons.rice_bowl,
  'dal': Icons.rice_bowl,
  'gram': Icons.rice_bowl,
  'chana': Icons.rice_bowl,
  'soybean': Icons.rice_bowl,
  'bhatmas': Icons.rice_bowl,
  'moong': Icons.rice_bowl,
  'honey': Icons.emoji_food_beverage,
  'ghee': Icons.water_drop,
  'oil': Icons.water_drop,
  'tea': Icons.local_cafe,
  'coffee': Icons.local_cafe,
  'egg': Icons.egg_alt,
  'milk': Icons.local_drink,
};
