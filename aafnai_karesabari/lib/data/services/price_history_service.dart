import '../models/market_price.dart';

abstract class PriceHistoryService {
  /// Returns null (not zero) when no record exists within the last 30 days.
  Future<PriceHistory?> recentPrice({required String productName, required String region});
}
