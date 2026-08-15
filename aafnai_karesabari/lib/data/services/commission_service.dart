/// Splits an order total into the platform's commission and the farmer's
/// payout.
///
/// This contract intentionally has no client-side calculator.
/// Cloud Functions must calculate and persist commission/payout atomically.
abstract class CommissionService {
  double calculateCommission(double totalPrice);
  double calculatePayout(double totalPrice);
}

class LocalCommissionService implements CommissionService {
  @override
  double calculateCommission(double totalPrice) => totalPrice * 0.05;

  @override
  double calculatePayout(double totalPrice) => totalPrice * 0.95;
}
