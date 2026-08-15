import 'package:flutter/material.dart';

/// Named text styles (titles, body, price, button) reused across screens
/// instead of each widget defining its own font size/weight.
abstract final class AppTypography {
  static const screenTitle = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2);
  static const sectionTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  static const body = TextStyle(fontSize: 15, height: 1.5);
  static const price = TextStyle(fontSize: 24, fontWeight: FontWeight.w800);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
}
