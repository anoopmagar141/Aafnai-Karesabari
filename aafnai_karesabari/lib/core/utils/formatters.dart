import '../constants/app_constants.dart';

String formatNpr(num amount) => '${AppConstants.currency} ${amount.toStringAsFixed(0)}';
