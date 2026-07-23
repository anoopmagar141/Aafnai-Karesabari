class PriceHistory {
  const PriceHistory({required this.id, required this.productName, required this.region, required this.low, required this.average, required this.high, required this.recordedAt});
  final String id, productName, region;
  final double low, average, high;
  final DateTime recordedAt;
  bool get isRecent => DateTime.now().difference(recordedAt).inDays <= 30;
}
