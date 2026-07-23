/// This contract intentionally has no client-side calculator.
/// Cloud Functions must calculate and persist commission/payout atomically.
abstract class CommissionService {
  Future<void> createOrder({required String listingId, required double quantity});
}
