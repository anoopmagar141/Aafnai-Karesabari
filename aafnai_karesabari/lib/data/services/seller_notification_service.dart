import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

/// Monitors new orders for the current seller and triggers notifications
class SellerNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<Order?> listenToNewOrdersForSeller() {
    final currentSellerId = _auth.currentUser?.uid;
    if (currentSellerId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('orders')
        .where('farmer_id', isEqualTo: currentSellerId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Order.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get pending orders count for seller
  Future<int> getPendingOrdersCount() async {
    final currentSellerId = _auth.currentUser?.uid;
    if (currentSellerId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('farmer_id', isEqualTo: currentSellerId)
          .where('status', isEqualTo: OrderStatus.pending.name)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting pending orders count: $e');
      return 0;
    }
  }

  /// Stream of pending orders count
  Stream<int> streamPendingOrdersCount() {
    final currentSellerId = _auth.currentUser?.uid;
    if (currentSellerId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('orders')
        .where('farmer_id', isEqualTo: currentSellerId)
        .where('status', isEqualTo: OrderStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get all active orders (pending + accepted) for dashboard badge
  Stream<int> streamActiveOrdersCount() {
    final currentSellerId = _auth.currentUser?.uid;
    if (currentSellerId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('orders')
        .where('farmer_id', isEqualTo: currentSellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final status = doc['status'] as String?;
            return status == OrderStatus.pending.name ||
                status == OrderStatus.accepted.name;
          })
          .length;
    });
  }
}
