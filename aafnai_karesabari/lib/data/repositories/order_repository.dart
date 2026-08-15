import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order.dart';
import 'firestore_repository.dart';

class OrderListFilter {
  const OrderListFilter({
    this.consumerId,
    this.farmerId,
    this.status,
    this.limit,
  });

  final String? consumerId;
  final String? farmerId;
  final OrderStatus? status;
  final int? limit;
}

/// CRUD + filtered listing for orders. Business rules (price validation,
/// notifications on status change) live in [OrderService], not here —
/// this layer only talks to Firestore/local storage.
abstract class OrderRepository {
  Future<Order> create(Order order);
  Future<void> update(Order order);
  Future<void> delete(String orderId);
  Future<Order?> getById(String orderId);
  Stream<Order?> stream(String orderId);
  Future<List<Order>> list({OrderListFilter? filter});
}

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({FirebaseFirestore? firestore})
      : _orders =
            (firestore ?? FirebaseFirestore.instance).collection('orders');

  final CollectionReference<Map<String, dynamic>> _orders;

  @override
  Future<Order> create(Order order) => runFirestore(() async {
        await _orders.doc(order.id).set(order.toFirestore());
        return order;
      }, message: 'Unable to create order.');

  @override
  Future<void> update(Order order) => runFirestore(
        () => _orders
            .doc(order.id)
            .set(order.toFirestore(), SetOptions(merge: true)),
        message: 'Unable to update order.',
      );

  @override
  Future<void> delete(String orderId) => runFirestore(
        () => _orders.doc(orderId).delete(),
        message: 'Unable to delete order.',
      );

  @override
  Future<Order?> getById(String orderId) => runFirestore(() async {
        final snapshot = await _orders.doc(orderId).get();
        if (!snapshot.exists) return null;
        return Order.fromFirestore(snapshot);
      }, message: 'Unable to load order.');

  @override
  Stream<Order?> stream(String orderId) {
    return mapDocumentStream(_orders.doc(orderId), Order.fromFirestore);
  }

  @override
  Future<List<Order>> list({OrderListFilter? filter}) => runFirestore(() async {
        Query<Map<String, dynamic>> query =
            _orders.orderBy('created_at', descending: true);

        final consumerId = filter?.consumerId;
        if (consumerId != null) {
          query = query.where('consumer_id', isEqualTo: consumerId);
        }

        final farmerId = filter?.farmerId;
        if (farmerId != null) {
          query = query.where('farmer_id', isEqualTo: farmerId);
        }

        final status = filter?.status;
        if (status != null) {
          query = query.where('status', isEqualTo: status.name);
        }

        final limit = filter?.limit;
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, Order.fromFirestore);
      }, message: 'Unable to load orders.');
}

class LocalOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};

  @override
  Future<Order> create(Order order) async {
    _orders[order.id] = order;
    return order;
  }

  @override
  Future<void> update(Order order) async {
    _orders[order.id] = order;
  }

  @override
  Future<void> delete(String orderId) async {
    _orders.remove(orderId);
  }

  @override
  Future<Order?> getById(String orderId) async => _orders[orderId];

  @override
  Stream<Order?> stream(String orderId) async* {
    yield _orders[orderId];
  }

  @override
  Future<List<Order>> list({OrderListFilter? filter}) async {
    var results = _orders.values.toList();
    final consumerId = filter?.consumerId;
    if (consumerId != null) {
      results =
          results.where((order) => order.consumerId == consumerId).toList();
    }
    final farmerId = filter?.farmerId;
    if (farmerId != null) {
      results = results.where((order) => order.farmerId == farmerId).toList();
    }
    final status = filter?.status;
    if (status != null) {
      results = results.where((order) => order.status == status).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limit = filter?.limit;
    if (limit != null) {
      return results.take(limit).toList(growable: false);
    }
    return results;
  }
}
