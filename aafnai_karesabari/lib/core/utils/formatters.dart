import '../constants/app_constants.dart';

/// Formats a number as an NPR currency string, e.g. `formatNpr(150)` -> "NPR 150".
String formatNpr(num amount) => '${AppConstants.currency} ${amount.toStringAsFixed(0)}';
