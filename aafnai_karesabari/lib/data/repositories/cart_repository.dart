import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_entry.dart';

abstract class CartRepository {
  Future<List<CartEntry>> loadCart();
  Future<void> saveCart(List<CartEntry> entries);
  Future<void> clearCart();
}

class SecureCartRepository implements CartRepository {
  SecureCartRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _cartKey = 'aafnai_karesabari_cart';
  final FlutterSecureStorage _storage;

  @override
  Future<List<CartEntry>> loadCart() async {
    final raw = await _storage.read(key: _cartKey);
    if (raw == null || raw.isEmpty) {
      return <CartEntry>[];
    }
    return CartEntry.listFromJson(raw);
  }

  @override
  Future<void> saveCart(List<CartEntry> entries) async {
    await _storage.write(key: _cartKey, value: CartEntry.listToJson(entries));
  }

  @override
  Future<void> clearCart() async {
    await _storage.delete(key: _cartKey);
  }
}

class LocalCartRepository implements CartRepository {
  LocalCartRepository({List<CartEntry>? seed})
      : _entries = List<CartEntry>.from(seed ?? const []);

  final List<CartEntry> _entries;

  @override
  Future<List<CartEntry>> loadCart() async => List<CartEntry>.from(_entries);

  @override
  Future<void> saveCart(List<CartEntry> entries) async {
    _entries
      ..clear()
      ..addAll(entries);
  }

  @override
  Future<void> clearCart() async {
    _entries.clear();
  }
}

class ResilientCartRepository implements CartRepository {
  ResilientCartRepository({CartRepository? primary, CartRepository? fallback})
      : _primary = primary ?? SecureCartRepository(),
        _fallback = fallback ?? LocalCartRepository();

  final CartRepository _primary;
  final CartRepository _fallback;

  @override
  Future<List<CartEntry>> loadCart() => _run((repository) => repository.loadCart());

  @override
  Future<void> saveCart(List<CartEntry> entries) =>
      _run((repository) => repository.saveCart(entries));

  @override
  Future<void> clearCart() => _run((repository) => repository.clearCart());

  Future<T> _run<T>(Future<T> Function(CartRepository repository) action) async {
    try {
      return await action(_primary);
    } catch (_) {
      return await action(_fallback);
    }
  }
}
