import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => FirestoreWishlistRepository(),
);

final wishlistNotifierProvider =
    StateNotifierProvider<WishlistNotifier, List<String>>((ref) {
  return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
});

class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier(this._repository) : super(const []) {
    _subscribe();
  }

  final WishlistRepository _repository;
  StreamSubscription<List<String>>? _subscription;

  void _subscribe() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _subscription = _repository.watchWishlist(uid).listen((ids) {
      state = ids;
    });
  }

  Future<void> toggle(String listingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (state.contains(listingId)) {
      await _repository.remove(uid, listingId);
    } else {
      await _repository.add(uid, listingId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
